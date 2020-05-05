//
//  StreamListController.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/4/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AntViewerExt

private let reuseIdentifier = "StreamCell"

class StreamListController: UICollectionViewController {

  fileprivate lazy var newLivesButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 10
    button.clipsToBounds = true
    button.backgroundColor = UIColor.color("a_button_blue")
    button.setImage(UIImage.image("ArrowSmallTop"), for: .normal)
    button.setTitle("NEW", for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 9, weight: .bold)
    button.setTitleColor(.white, for: .normal)
    button.semanticContentAttribute = .forceRightToLeft
    view.addSubview(button)
    button.addTarget(self, action: #selector(scrollToTop), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
      button.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
      button.heightAnchor.constraint(equalToConstant: 21),
      button.widthAnchor.constraint(equalToConstant: 80)
    ])
    return button
  }()

  fileprivate var swiftMessage: SwiftMessage?
  private lazy var bottomMessage = BottomMessage(presentingController: self)

  fileprivate var activeCell: StreamCell? {
    didSet {
      oldValue?.contentImageView.player = nil
      oldValue?.timeImageView.stopAnimating()
      player.stop()
      playerDebouncer.call {}
      guard let item = activeItem else { return }
      playerDebouncer.call { [weak self] in
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        self?.activeCell?.replayView.isHidden = true
        self?.activeCell?.contentImageView.playerLayer.videoGravity = .resizeAspectFill
        self?.activeCell?.contentImageView.player = self?.player.player
        let media = ModernAVPlayerMedia(url: URL(string: item.url)!, type: .stream(isLive: item is Live))
        var position: Double?
        if let item = item as? VOD {
          position = Double(self?.stopTimes[item.streamId] ?? item.stopTime.duration())
        }
        self?.player.load(media: media, autostart: true, position: position)
      }
    }
  }
  
  private var footerView: FooterView? {
    didSet {
      footerView?.jumpAction = { [weak self] in
        self?.scrollToTop()
      }
      updateFooter()
    }
  }

  fileprivate var activeItem: VideoContent? {
    guard let cell = activeCell,
      let index = collectionView.indexPath(for: cell) else {
        return nil
    }
    return getItemWith(indexPath: index)
  }

  fileprivate lazy var player: ModernAVPlayer = {
    let player = ModernAVPlayer()
    player.player.isMuted = true
    player.delegate = self
    return player
  }()

  fileprivate let playerDebouncer = Debouncer(delay: 1.2)
  fileprivate var isLoading = false {
    didSet {
      collectionView.isUserInteractionEnabled = !isLoading
    }
  }
  
  fileprivate var isDataSourceEmpty: Bool {
    return dataSource.videos.isEmpty && dataSource.streams.isEmpty
  }
  fileprivate var isReachable: Bool {
    URLSessionNetworkDispatcher.instance.isReachable
  }

  var dataSource: DataSource!

  private var fetchingNextItems = false {
    didSet {
      updateFooter()
    }
  }
  fileprivate var reachedListsEnd = false {
    didSet {
      updateFooter()
    }
  }

  private lazy var refreshControl: AntRefreshControl = {
    let antRefreshControl = AntRefreshControl(frame: self.view.bounds)
    antRefreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
    return antRefreshControl
  }()

  private var hiddenAuthCompleted = false
  fileprivate var shouldResetActiveCell = true
  
  var onViewerDismiss: ((NSDictionary) -> Void)?

  // MARK: Temp solution
  fileprivate var stopTimes = [Int : Int]()

  override func viewDidLoad() {
    super.viewDidLoad()
    AntViewerManager.shared.hiddenAuthIfNeededWith { [weak self] (result) in
      self?.hiddenAuthCompleted = true
      switch result {
      case .success():
        self?.initialVodsUpdate()
      case .failure(let error):
        print(error)
      }
    }
    swiftMessage = SwiftMessage(presentingController: navigationController ?? self)
    setupNavigationBar()
    setupCollectionView()
    isLoading = true
    initialVodsUpdate()

    bottomMessage.onMessageAppear = { [weak self] height in
      UIView.animate(withDuration: 0.3) {
        self?.collectionView.frame.size.height -= height
      }
    }
    bottomMessage.onMessageDisappear = { [weak self] height in
      UIView.animate(withDuration: 0.3) {
        self?.collectionView.frame.size.height += height
      }
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "StreamsUpdated"), object: nil, queue: .main) { [weak self](notification) in
      let addedCount = notification.userInfo?["addedCount"] as? Int ?? 0
      let deleted = notification.userInfo?["deleted"] as? [Int] ?? []
      self?.reloadCollectionViewDataSource(addedCount: addedCount, deletedIndexes: deleted)
    }

    collectionView.alwaysBounceVertical = true
    collectionView.refreshControl = refreshControl
    
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    collectionView.reloadData()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if activeCell == nil {
      activeCell = getTopVisibleCell()
    }
    startObservingReachability()
  }

  func startObservingReachability() {
    if !isReachable {
      let color = UIColor.color("a_bottomMessageGray")
      bottomMessage.showMessage(title: "NO CONNECTION", backgroundColor: color ?? .gray)
    }
    NotificationCenter.default.addObserver(self, selector: #selector(handleReachability(_:)), name: .reachabilityChanged, object: nil)
  }

  func stopObservingReachability() {
    NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
    bottomMessage.hideMessage()
  }

  @objc
  private func handleReachability(_ notification: Notification) {
    if isReachable {
      let color = UIColor.color("a_bottomMessageGreen")
      bottomMessage.showMessage(title: "YOU ARE ONLINE", duration: 2, backgroundColor: color ?? .green)
      if collectionView.numberOfItems(inSection: 1) == 0 {
        initialVodsUpdate()
      }
    } else {
      let color = UIColor.color("a_bottomMessageGray")
      bottomMessage.showMessage(title: "NO CONNECTION", backgroundColor: color ?? .gray)
    }
  }


  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    stopObservingReachability()
    activeCell = nil
    if collectionView.contentOffset.y < 0 {
      collectionView.contentOffset = .zero
    }
  }

  func updateFooter() {
    guard fetchingNextItems || reachedListsEnd else {
      footerView?.isHidden = true
      footerView?.stopAnimating()
      return
    }

    if fetchingNextItems {
      let isEnoughContent = collectionView.contentSize.height > collectionView.bounds.height
      if isEnoughContent {
        footerView?.startAnimating()
        footerView?.showButton = false
      }
      footerView?.isHidden = !isEnoughContent
    } else {
      footerView?.stopAnimating()
      let isEnoughContent = collectionView.contentSize.height > 2 * collectionView.bounds.height
      footerView?.showButton = isEnoughContent
      footerView?.isHidden = !isEnoughContent
    }

  }

  @objc
  fileprivate func scrollToTop() {
    newLivesButton.isHidden = true
    collectionView.setContentOffset(.zero, animated: true)
  }
  
  private func initialVodsUpdate() {
    dataSource.updateVods { [weak self] (result) in
      guard let `self` = self else { return }
      switch result {
      case .success:
        if !self.isDataSourceEmpty {
          self.isLoading = false
        }
        self.collectionView.reloadData()
        if self.activeCell == nil {
          self.activeCell = self.getTopVisibleCell()
        }
      case .failure(let error):
        print(error)
        if !error.noInternetConnection && self.hiddenAuthCompleted {
          self.swiftMessage?.showBanner(title: error.localizedDescription )
        }
      }
    }
  }

  @objc
  private func handleWillResignActive(_ notification: NSNotification) {
    if collectionView.contentOffset.y < 0 {
      collectionView.contentOffset = .zero
    }
    activeCell = nil
  }

  @objc
  private func handleDidBecomeActive(_ notification: NSNotification) {
    if collectionView.contentOffset.y < 0 {
       collectionView.contentOffset = .zero
     }
    activeCell = getTopVisibleCell()
  }
  
  private func reloadCollectionViewDataSource(addedCount: Int, deletedIndexes: [Int]) {
    guard var visibleIndexPath = getTopVisibleRow(),
      var differenceBetweenRowAndNavBar = heightDifferenceBetweenTopRowAndNavBar() else {
        reachedListsEnd = false
        collectionView.reloadData()
        return
    }
    var shouldScroll = true
    let streamsCount = dataSource.streams.count
    if visibleIndexPath.section == 0 {
      let itemsCount = collectionView.numberOfItems(inSection: 0)
      if streamsCount == 0 {
        shouldScroll = dataSource.videos.count > 0
        differenceBetweenRowAndNavBar = 0
        visibleIndexPath = IndexPath(item: 0, section: 1)
      } else {
        let difference = streamsCount - itemsCount
        let newItem = max(visibleIndexPath.item + difference, 0)
        visibleIndexPath.item = newItem
      }
    }

    UIView.performWithoutAnimation {
      let deletedPaths = deletedIndexes.map { IndexPath(item: $0, section: 0) }
      var addedPaths = [IndexPath]()
      for index in 0 ..< addedCount {
        addedPaths.append(IndexPath(item: index, section: 0))
      }
      collectionView.performBatchUpdates({
        collectionView.deleteItems(at: deletedPaths)
        collectionView.insertItems(at: addedPaths)
      }, completion: nil)

      if addedCount > 0, newLivesButton.isHidden {
        let shouldShow = visibleIndexPath.section == 1 || visibleIndexPath.item > 0
        newLivesButton.isHidden = !shouldShow
      } else if streamsCount == 0 {
        newLivesButton.isHidden = true
      }
      if shouldScroll {
        shouldResetActiveCell = false
        collectionView.scrollToItem(at: visibleIndexPath, at: .top, animated: false)
        collectionView.contentOffset.y = collectionView.contentOffset.y - differenceBetweenRowAndNavBar
        shouldResetActiveCell = true
      }
    }

  }
  
  private func setupNavigationBar() {
    navigationController?.navigationBar.barTintColor = collectionView.backgroundColor
    navigationController?.navigationBar.updateBackgroundColor()
    navigationController?.navigationBar.shadowImage = UIColor.white.withAlphaComponent(0.2).as1ptImage()

    let closeButton = UIButton(type: .custom)
    closeButton.setImage(UIImage.image("Close"), for: .normal)
    closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
    closeButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
    navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: closeButton)]

    let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15, weight: .medium), NSAttributedString.Key.foregroundColor : UIColor.white]
    navigationController?.navigationBar.titleTextAttributes = attributes
    navigationItem.title = "INSIDE THE GAME"
    
    let changeHost = UIButton(type: .custom)
    changeHost.setImage(UIImage.image("HolderLogoSmall"), for: .normal)
    changeHost.addTarget(self, action: #selector(changeHost(_:event:)), for: .touchDownRepeat)
    changeHost.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
    navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: changeHost)]
  }
  
  @objc
  private func didPullToRefresh(_ sender: Any) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      self?.dataSource.updateVods { (result) in
        self?.refreshControl.endRefreshing()
        switch result {
        case .success:
          self?.reachedListsEnd = false
          self?.collectionView.reloadData()
        case .failure(let error):
          if !error.noInternetConnection && self?.hiddenAuthCompleted == true {
            self?.swiftMessage?.showBanner(title: error.localizedDescription )
          }
        }
      }
    }
  }
  
  private func setupCollectionView() {
    let cellNib = UINib(nibName: "StreamCell", bundle: Bundle(for: type(of: self)))
    collectionView.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
    let footerNib = UINib(nibName: "FooterView", bundle: Bundle(for: type(of: self)))
    collectionView.register(footerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "AntFooterView")
    collectionView.showsVerticalScrollIndicator = false
    collectionView.reloadData()
  }
  
  @objc
  private func changeHost(_ sender: UIButton, event: UIEvent) {
    guard let touches = event.allTouches?.first, touches.tapCount == 3 else {
      return
    }
    let version = Bundle(identifier: "org.cocoapods.AntWidget")?.infoDictionary?["CFBundleShortVersionString"] as? String
    presentChangeHostAlert(with: version)
    
  }
  
  @objc
  private func closeButtonPressed(_ sender: UIButton) {
    onViewerDismiss?([:])
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ViewerWillDisappear"), object: nil)
    dismiss(animated: true, completion: { [weak self] in
      self?.dataSource.videos = []
    })
  }
  
  fileprivate func configureCell(_ cell: StreamCell, forIndexPath indexPath: IndexPath) -> StreamCell {
    let item = getItemWith(indexPath: indexPath)
    cell.titleLabel.text = item.title
    cell.subtitleLabel.text = "\(item.creatorName) • \(item.date.timeAgo())"
    cell.joinButton.isHidden = item is VOD || !item.isChatOn
    cell.chatView.isHidden = !item.isChatOn
    cell.pollView.isHidden = !item.isPollOn
    cell.shareButton.isHidden = true
    cell.buttonsStackView.isHidden = !item.isChatOn && !item.isPollOn
    cell.message = item.latestMessage
    cell.viewersCountLabel.text = "\(item.viewsCount)"
    cell.userImageView.load(url: URL(string: item.broadcasterPicUrl), placeholder: UIImage.image("avaPic"))
    cell.contentImageView.load(url: URL(string: item.thumbnailUrl), placeholder: UIImage.image("PlaceholderVideo"))
    if let item = item as? VOD {
      cell.isNew = item.isNew
      cell.duration = item.duration.duration()
      //Temp solution
      cell.watchedTime = item.isNew ? 0 : stopTimes[item.streamId] ?? item.stopTime.duration()
      cell.replayView.isHidden = true
    } else if let item = item as? Live {
      cell.isLive = true
      let duration = Date().timeIntervalSince(item.date)
      cell.duration = Int(duration)
      cell.watchedTime = 0
      cell.replayView.isHidden = true
      cell.joinAction = { itemCell in
        //TOD: open player with active field
      }
    }
    return cell
  }
  
  fileprivate func getItemWith(indexPath: IndexPath) -> VideoContent {
    if dataSource.streams.isEmpty || dataSource.videos.isEmpty {
      return dataSource.streams.isEmpty ? dataSource.videos[indexPath.row] : dataSource.streams.reversed()[indexPath.row]
    } else {
      return indexPath.section == 0 ? dataSource.streams.reversed()[indexPath.row] : dataSource.videos[indexPath.row]
    }
  }

  fileprivate func getTopVisibleRow () -> IndexPath? {
    guard let navBar = navigationController?.navigationBar else { return nil }
    let whereIsNavBarInTableView = collectionView.convert(navBar.bounds, from: navBar)
    let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height + 1)
    let accurateIndexPath = collectionView.indexPathForItem(at: pointWhereNavBarEnds)
    return accurateIndexPath
  }

  fileprivate func heightDifferenceBetweenTopRowAndNavBar() -> CGFloat? {
    let rectForTopRow = collectionView.layoutAttributesForItem(at: getTopVisibleRow()!)!.frame
    let navBar = navigationController?.navigationBar
    let whereIsNavBarInTableView = collectionView.convert(navBar!.bounds, from: navBar)
    let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height)
    let differenceBetweenTopRowAndNavBar = rectForTopRow.origin.y - pointWhereNavBarEnds.y
    return differenceBetweenTopRowAndNavBar
  }

  fileprivate func getTopVisibleCell() -> StreamCell? {
    let cell = collectionView.visibleCells.last(where: {
      let cellRect = $0.frame
      var listRect = self.collectionView.bounds
      listRect.origin.y -= cellRect.height * 0.25
      listRect.size.height += cellRect.height * 0.4
      return listRect.contains(cellRect)
    })
    return cell as? StreamCell
  }

}


// MARK: UIScrollViewDelegate
extension StreamListController {
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    refreshControl.scrollViewDidScroll(scrollView)
    resetActiveCell()
  }

  override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
    setActiveCell()
  }
  override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    setActiveCell()
  }

  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    setActiveCell()
  }

  override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      setActiveCell()
    }
  }

  private func setActiveCell() {
    if let cell = getTopVisibleCell(), activeCell != cell {
      activeCell = cell
    }
  }

  private func resetActiveCell() {
    if getTopVisibleCell() != activeCell, shouldResetActiveCell {
      activeCell = nil
    }
  }

}

// MARK: UICollectionViewDataSource
extension StreamListController {
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if !isDataSourceEmpty {
      collectionView.backgroundView = nil
    }
    return section == 0 ? dataSource.streams.count : dataSource.videos.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! StreamCell
    return configureCell(cell, forIndexPath: indexPath)
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    if case UICollectionView.elementKindSectionFooter = kind {
      let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "AntFooterView", for: indexPath) as! FooterView
      self.footerView = footer
      return footer
    }
    return UICollectionReusableView()
  }
  
}

// MARK: UICollectionViewDelegate
extension StreamListController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard isReachable else {
      self.swiftMessage?.showBanner(title: "No internet connection available" )
      return
    }
    let item = getItemWith(indexPath: indexPath)
    let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
    playerVC.videoContent = item
    playerVC.dataSource = dataSource
    // TODO: set temp stop time from list
    if item is VOD {
      let navController = PlayerNavigationController(rootViewController: playerVC)
      navController.modalPresentationStyle = .fullScreen
      return present(navController, animated: true, completion: nil)
    }
    playerVC.modalPresentationStyle = .fullScreen
    present(playerVC, animated: true, completion: nil)
  }
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if indexPath.section == 0, indexPath.item == 0 {
      newLivesButton.isHidden = true
    }
    guard indexPath.section == 1, indexPath.row == dataSource.videos.count - 1, !isLoading else {
      return
    }
    if dataSource.videos.count % 15 == 0 {
      let index = dataSource.videos.count
      self.fetchingNextItems = true
      self.collectionView.invalidateIntrinsicContentSize()
      dataSource.fetchNextItemsFrom(index: index) { [weak self] (result) in
        guard let `self` = self else { return }
        self.fetchingNextItems = false
        self.collectionView.invalidateIntrinsicContentSize()
        switch result {
        case .success :
          let count = self.dataSource.videos.count
          let indexPaths = (index..<count).map {IndexPath(row: $0, section: 1)}
          self.collectionView.insertItems(at: indexPaths)

        case .failure(let error):
          self.swiftMessage?.showBanner(title: error.noInternetConnection ? "No internet connection available" : error.localizedDescription )
          print("Error fetching vods")
        }

      }
    } else {
      reachedListsEnd = true
    }
  }
}

// MARK: UICollectionViewDelegateFlowLayout
extension StreamListController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    var height = view.bounds.width
    let item = getItemWith(indexPath: indexPath)
    if let message = item.latestMessage?.text {
      let width = view.bounds.width - 40
      let labelHeight = message.height(withConstrainedWidth: width, font: .systemFont(ofSize: 12))
      height += labelHeight + 2 + 12 + 14.5
    }
    if item.isChatOn || item.isPollOn || item.shareLink != nil {
      height += 12 + 0.075 * view.bounds.width
    }
    if item is Live, item.isChatOn {
      height += 20 + 12
    }
    return CGSize(width: view.bounds.width, height: height)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    let size = CGSize(width: collectionView.bounds.width, height: section == 1 ? 50 : 0)
    if reachedListsEnd, collectionView.contentSize.height > view.bounds.height {
      return size
    }
    guard !fetchingNextItems, !self.isLoading else {
      return .zero
    }
    return size
  }
}

extension StreamListController: ModernAVPlayerDelegate {
  public func modernAVPlayer(_ player: ModernAVPlayer, didStateChange state: ModernAVPlayer.State) {
    switch state {
    case .failed:
      activeCell = nil
    default:
      return
    }
  }

  public func modernAVPlayer(_ player: ModernAVPlayer, didItemPlayToEndTime endTime: Double) {
    DispatchQueue.main.async { [weak self] in
      self?.activeCell?.replayView.isHidden = false
      self?.activeCell?.timeImageView.stopAnimating()
    }

  }

  public func modernAVPlayer(_ player: ModernAVPlayer, didCurrentTimeChange currentTime: Double) {
    DispatchQueue.main.async { [weak self] in
      if let item = self?.activeItem as? VOD {
        self?.activeCell?.duration = item.duration.duration()
        self?.activeCell?.watchedTime = Int(currentTime)
        self?.stopTimes[item.streamId] = Int(currentTime)
      } else if let item = self?.activeItem as? Live {
        let duration = Date().timeIntervalSince(item.date)
        self?.activeCell?.duration = Int(duration)
      }
    }
  }

  public func modernAVPlayer(_ player: ModernAVPlayer, didItemDurationChange itemDuration: Double?) {
    DispatchQueue.main.async { [weak self] in
      self?.activeCell?.timeImageView.startAnimating()
    }
  }

}

