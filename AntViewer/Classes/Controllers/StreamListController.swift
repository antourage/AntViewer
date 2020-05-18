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

class StreamListController: UIViewController {

  @IBOutlet private var headerView: UIView!
  @IBOutlet private var collectionView: UICollectionView!
  @IBOutlet private var logoImageView: UIImageView!
  @IBOutlet private var collectionViewBottom: NSLayoutConstraint!
  @IBOutlet private var headerTop: NSLayoutConstraint!



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
    button.contentHorizontalAlignment = .center
    button.contentEdgeInsets.left = 3
    view.addSubview(button)
    button.addTarget(self, action: #selector(scrollToTop), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
      button.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
      button.heightAnchor.constraint(equalToConstant: 21),
      button.widthAnchor.constraint(equalToConstant: button.intrinsicContentSize.width+10)
    ])
    return button
  }()

  fileprivate var swiftMessage: SwiftMessage?
  private lazy var bottomMessage = BottomMessage(presentingController: self)

  fileprivate var activeCell: StreamCell? {
    didSet {
      oldValue?.contentImageView.player = nil
      oldValue?.timeImageView.isHidden = true
      oldValue?.timeImageView.stopAnimating()
      player.stop()
      playerDebouncer.call {}
      guard let item = activeItem else { return }
      playerDebouncer.call { [weak self] in
//        let generator = UISelectionFeedbackGenerator()
//        generator.selectionChanged()
        self?.activeCell?.replayView.isHidden = true
        self?.activeCell?.contentImageView.playerLayer.videoGravity = .resizeAspectFill
        self?.activeCell?.contentImageView.player = self?.player.player
        let media = ModernAVPlayerMedia(url: URL(string: item.url)!, type: .stream(isLive: item is Live))
        var position: Double?
        if let item = item as? VOD {
          position = Double(self?.stopTimes[item.id] ?? item.stopTime.duration())
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

  lazy var skeleton: Skeleton? = {
    let skeleton = Skeleton()
    skeleton.delegate = self
    return skeleton
  }()

  private var hiddenAuthCompleted = false
  fileprivate var shouldResetActiveCell = true
  
  var onViewerDismiss: ((NSDictionary) -> Void)?

  // MARK: Temp solution
  fileprivate var stopTimes = [Int : Int]()

  private var topInset: CGFloat = .zero

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
    dataSource.lastMessageHandler = MessageFetcher()
    if dataSource.streams.isEmpty {
      skeleton?.collectionView = collectionView
    }


    swiftMessage = SwiftMessage(presentingController: navigationController ?? self)
//    setupNavigationBar()
    setupCollectionView()
    isLoading = true
    initialVodsUpdate()

    bottomMessage.onMessageAppear = { [weak self] height in
      self?.collectionViewBottom.constant += height
      UIView.animate(withDuration: 0.3) {
        self?.view.layoutIfNeeded()
      }
    }
    bottomMessage.onMessageDisappear = { [weak self] height in
      self?.collectionViewBottom.constant -= height
      UIView.animate(withDuration: 0.3) {
        self?.view.layoutIfNeeded()
      }
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "StreamsUpdated"), object: nil, queue: .main) { [weak self](notification) in
      let addedCount = notification.userInfo?["addedCount"] as? Int ?? 0
      let deleted = notification.userInfo?["deleted"] as? [Int] ?? []
      self?.reloadCollectionViewDataSource(addedCount: addedCount, deletedIndexes: deleted)
      self?.skeleton?.loaded(videoContent: Live.self, isEmpty: self?.dataSource.streams.isEmpty ?? true)
//      self?.collectionView.collectionViewLayout.invalidateLayout()
    }

    collectionView.alwaysBounceVertical = true
    collectionView.refreshControl = refreshControl
    topInset = view.safeAreaInsets.top
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
    topInset = headerView.frame.origin.y
  }

  func startObservingReachability() {
    if !isReachable {
      let color = UIColor.color("a_bottomMessageGray")
      bottomMessage.showMessage(title: "NO CONNECTION", backgroundColor: color ?? .gray)
    }
    skeleton?.didChangeReachability(isReachable)
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
    skeleton?.didChangeReachability(isReachable)
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

  deinit {
    dataSource.lastMessageHandler = nil
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
    collectionView.setContentOffset(.zero, animated: true)
  }
  
  private func initialVodsUpdate() {
    dataSource.updateVods { [weak self] (result) in
      guard let `self` = self else { return }
      switch result {
      case .success:
        self.skeleton?.loaded(videoContent: VOD.self , isEmpty: self.dataSource.videos.isEmpty)
        self.collectionView.reloadData()
        if self.activeCell == nil {
          self.activeCell = self.getTopVisibleCell()
        }
        self.isLoading = false
      case .failure(let error):
        print(error)
        if !error.noInternetConnection && self.hiddenAuthCompleted {
          self.bottomMessage.showMessage(title: "Something is not right")
          self.skeleton?.setError()
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
        if skeleton == nil {
          collectionView.reloadData()
        }
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
  
  @objc
  private func didPullToRefresh(_ sender: Any) {
    skeleton?.startLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      self?.dataSource.updateVods { (result) in
        self?.refreshControl.endRefreshing()
        switch result {
        case .success:
          self?.reachedListsEnd = false
          self?.skeleton?.loaded(videoContent: VOD.self, isEmpty: self?.isDataSourceEmpty == true)
          self?.collectionView.reloadData()
        case .failure(let error):
          if !error.noInternetConnection && self?.hiddenAuthCompleted == true {
            self?.skeleton?.setError()
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
  
  @IBAction
  private func changeHost(_ sender: UITapGestureRecognizer) {
    let version = Bundle(identifier: "org.cocoapods.AntWidget")?.infoDictionary?["CFBundleShortVersionString"] as? String
    presentChangeHostAlert(with: version)
    
  }
  
  @IBAction
  private func closeButtonPressed(_ sender: UIButton) {
    onViewerDismiss?([:])
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ViewerWillDisappear"), object: nil)
    let transition = CATransition()
    transition.duration = 0.3
    transition.type = .push
    transition.subtype = .fromLeft
    transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
    view.window?.layer.add(transition, forKey: kCATransition)
    dismiss(animated: false, completion: { [weak self] in
      self?.dataSource.videos = []
    })
  }
  
  fileprivate func configureCell(_ cell: StreamCell, forIndexPath indexPath: IndexPath) -> StreamCell {
    let item = getItemWith(indexPath: indexPath)
    cell.titleLabel.text = item.title
    cell.subtitleLabel.text = "\(item.creatorNickname) • \(item.date.timeAgo())"
    cell.joinButton.isHidden = item is VOD || !item.isChatOn
    cell.chatView.isHidden = true
    cell.pollView.isHidden = true
    cell.shareButton.isHidden = true
    cell.chatEnabled = item.isChatOn
    cell.message = item.latestMessage
    cell.viewersCountLabel.text = "\(item.viewsCount)"
    cell.userImageView.load(url: URL(string: item.broadcasterPicUrl), placeholder: UIImage.image("avaPic"))
    cell.contentImageView.load(url: URL(string: item.thumbnailUrl), placeholder: UIImage.image("PlaceholderVideo"))
    if let item = item as? VOD {
      cell.chatView.isHidden = item.latestMessage == nil
      cell.isLive = false
      cell.isNew = item.isNew
      cell.duration = item.duration.duration()
      //Temp solution
      let duration = item.stopTime.duration() == 0 ? nil : item.stopTime.duration()
      cell.watchedTime = item.isNew ? nil : stopTimes[item.id] ?? duration
      cell.replayView.isHidden = true
    } else if let item = item as? Live {
      cell.chatView.isHidden = !((item.latestMessage == nil) || item.isChatOn)
      cell.isLive = true
      cell.pollView.isHidden = !item.isPollOn
      let duration = Date().timeIntervalSince(item.date)
      cell.duration = Int(duration)
      cell.replayView.isHidden = true
      cell.joinAction = { itemCell in
        //TOD: open player with active field
      }
    }

    cell.buttonsStackView.isHidden = cell.chatView.isHidden && !item.isPollOn
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
    let whereIsNavBarInTableView = collectionView.convert(headerView.bounds, from: headerView)
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
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    refreshControl.scrollViewDidScroll(scrollView)
    resetActiveCell()
    if newLivesButton.isHidden == false, scrollView.contentOffset.y < 250 {
      newLivesButton.isHidden = true
    }
  }

  func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
    setActiveCell()
  }
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    setActiveCell()
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    setActiveCell()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
extension StreamListController: UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if !isDataSourceEmpty {
      collectionView.backgroundView = nil
    }
    return section == 0 ? dataSource.streams.count : dataSource.videos.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! StreamCell
    return configureCell(cell, forIndexPath: indexPath)
  }
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    if case UICollectionView.elementKindSectionFooter = kind {
      let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "AntFooterView", for: indexPath) as! FooterView
      self.footerView = footer
      return footer
    }
    return UICollectionReusableView()
  }
  
}

// MARK: UICollectionViewDelegate
extension StreamListController: UICollectionViewDelegate {
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard isReachable else { return }

    let item = getItemWith(indexPath: indexPath)
    let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
    playerVC.videoContent = item
    playerVC.dataSource = dataSource
    // TODO: set temp stop time from list

    //temp solution
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) { [weak self] in
      guard let `self` = self, OrientationUtility.isLandscape else { return }
      collectionView.contentOffset = CGPoint(x: self.topInset, y: collectionView.contentOffset.y)
      collectionView.collectionViewLayout.invalidateLayout()
      self.headerTop.constant = self.topInset
      self.view.layoutIfNeeded()
    }

    if item is VOD {
      let navController = PlayerNavigationController(rootViewController: playerVC)
      navController.modalPresentationStyle = .fullScreen
      return present(navController, animated: true, completion: { [weak self] in
        self?.headerTop.constant = .zero
        self?.view.layoutIfNeeded()
      })
    }
    playerVC.modalPresentationStyle = .fullScreen
    present(playerVC, animated: true, completion: { [weak self] in
      self?.headerTop.constant = .zero
       self?.view.layoutIfNeeded()
    })
  }
  
   func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
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

        case .failure:
          if self.isReachable {
            let color = UIColor.color("a_bottomMessageGray")
            self.bottomMessage.showMessage(title: "SOMETHING IS NOT RIGHT. WE ARE WORKING TO GET THIS FIXED.",duration: 5, backgroundColor: color ?? .gray)
            print("Error fetching vods")
          }
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
    if (item.isChatOn && item is Live || item.latestMessage != nil && item is VOD) || item.isPollOn || item.shareLink != nil {
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
      self?.activeCell?.timeImageView.isHidden = true
      self?.activeCell?.timeImageView.stopAnimating()
    }

  }

  public func modernAVPlayer(_ player: ModernAVPlayer, didCurrentTimeChange currentTime: Double) {
    DispatchQueue.main.async { [weak self] in
      if let item = self?.activeItem as? VOD {
        self?.activeCell?.duration = item.duration.duration()
        self?.activeCell?.watchedTime = Int(currentTime)
        self?.stopTimes[item.id] = Int(currentTime)
      } else if let item = self?.activeItem as? Live {
        let duration = Date().timeIntervalSince(item.date)
        self?.activeCell?.duration = Int(duration)
      }
    }
  }

  public func modernAVPlayer(_ player: ModernAVPlayer, didItemDurationChange itemDuration: Double?) {
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      self.activeCell?.timeImageView.isHidden = false
      self.activeCell?.timeImageView.startAnimating()
    }
  }

}

extension StreamListController: SkeletonDelegate {
  func skeletonWillHide(_ skeleton: Skeleton) {
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.isUserInteractionEnabled = true
    collectionView.reloadData()
    skeleton.delegate = nil
    self.skeleton = nil
  }

  func skeletonOnTimeout(_ skeleton: Skeleton) {
    //TODO: set error
  }
}
