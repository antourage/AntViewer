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
  @IBOutlet private var tagLineLabel: UILabel!
  @IBOutlet private var collectionViewBottom: NSLayoutConstraint!
  @IBOutlet private var headerTop: NSLayoutConstraint!



  fileprivate lazy var newLivesButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 10
    button.clipsToBounds = true
    button.backgroundColor = UIColor.color("a_button_blue")
    button.setImage(UIImage.image("ArrowSmallTop"), for: .normal)
    button.setTitle(LocalizedStrings.new.localized.uppercased(), for: .normal)
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

  private lazy var bottomMessage = BottomMessage(presentingController: self)

  fileprivate var activeCell: StreamCell? {
    didSet {
      oldValue?.contentImageView.player = nil
      oldValue?.timeImageView.isHidden = true
      oldValue?.timeImageView.stopAnimating()
      curtainThumbnail.removeFromSuperview()
      player.stop()
      playerDebouncer.call {}
      guard let item = activeItem else { return }
      playerDebouncer.call { [weak self] in
        self?.activeCell?.replayView.isHidden = true
        self?.activeCell?.contentImageView.playerLayer.videoGravity = .resizeAspectFill
        self?.activeCell?.contentImageView.player = self?.player.player
        guard let url = URL(string: item.url) else { return }
        let media = ModernAVPlayerMedia(url: url, type: .stream(isLive: item is Live))
        var position: Double?
        if let item = item as? VOD {
          position = Double(item.stopTime.duration())
        }
        if let fakeThumb = self?.curtainThumbnail, let contentImageView = self?.activeCell?.contentImageView {
          contentImageView.addSubview(fakeThumb)
          fakeThumb.fixInView(contentImageView)
          fakeThumb.image = contentImageView.image
          fakeThumb.contentMode = .scaleAspectFill
        }
        self?.player.load(media: media, autostart: true, position: position)
      }
    }
  }

  private let curtainThumbnail = UIImageView()
  
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

  fileprivate let playerDebouncer = Debouncer(delay: 0.5)
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
    antRefreshControl.shouldAnimate = isReachable
    return antRefreshControl
  }()

  lazy var skeleton: Skeleton? = {
    let skeleton = Skeleton()
    skeleton.delegate = self
    return skeleton
  }()

  private var hiddenAuthCompleted = false
  fileprivate var shouldResetActiveCell = true

  override var preferredStatusBarStyle: UIStatusBarStyle {
      .lightContent
  }

  private var topInset: CGFloat = .zero
  private var failedToLoadVods = false

  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ViewerWillAppear"), object: nil)
    AntViewerManager.shared.hiddenAuthIfNeededWith { [weak self] (result) in
      self?.hiddenAuthCompleted = true
      switch result {
      case .success():
        self?.initialVodsUpdate()
      case .failure(let error):
        print(error)
      }
    }
    configureHeader()
    dataSource.firebaseFetcher = MessageFetcher()
    if dataSource.streams.isEmpty {
      skeleton?.collectionView = collectionView
    }

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
      self?.collectionViewBottom.constant = 0
      UIView.animate(withDuration: 0.3) {
        self?.view.layoutIfNeeded()
      }
    }
    NotificationCenter.default.addObserver(self, selector: #selector(streamsDidUpdate(_:)), name: NSNotification.Name.init(rawValue: "StreamsUpdated"), object: nil)
    collectionView.alwaysBounceVertical = true
    collectionView.refreshControl = refreshControl
    topInset = view.safeAreaInsets.top
    skeleton?.loaded(videoContent: Live.self, isEmpty: dataSource.streams.isEmpty)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    collectionView.reloadData()
//    collectionView.isUserInteractionEnabled = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setNeedsStatusBarAppearanceUpdate()
    activeCell = getTopVisibleCell()
    startObservingReachability()
    topInset = headerView.frame.origin.y
  }

  func startObservingReachability() {
    if !isReachable {
      let color = UIColor.color("a_bottomMessageGray")
      bottomMessage.showMessage(title: LocalizedStrings.noConnection.localized.uppercased(), backgroundColor: color ?? .gray)
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
      bottomMessage.showMessage(title: LocalizedStrings.youAreOnline.localized.uppercased(), duration: 2, backgroundColor: color ?? .green)
      if collectionView.numberOfItems(inSection: 1) == 0 {
        initialVodsUpdate()
      } else {
        if let lastCell = collectionView.cellForItem(at: IndexPath(item: dataSource.videos.count-1, section: 1)),
          collectionView.visibleCells.contains(lastCell), failedToLoadVods {
          fetchNextBunchOfVods()
        }
      }
    } else {
      let color = UIColor.color("a_bottomMessageGray")
      bottomMessage.showMessage(title: LocalizedStrings.noConnection.localized.uppercased(), backgroundColor: color ?? .gray)
    }
    refreshControl.shouldAnimate = isReachable
    skeleton?.didChangeReachability(isReachable)
  }


  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    stopObservingReachability()
    activeCell = nil
    if collectionView.contentOffset.y < 0 {
      collectionView.contentOffset = .zero
    }
  }

  deinit {
    dataSource.firebaseFetcher = nil
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
        self.bottomMessage.hideMessage()
        self.skeleton?.loaded(videoContent: VOD.self , isEmpty: self.dataSource.videos.isEmpty)
        self.collectionView.reloadData()
        self.collectionView.performBatchUpdates(nil) { (result) in
          if self.activeCell == nil, self.view.window != nil {
            self.activeCell = self.getTopVisibleCell()
          }
        }
        self.isLoading = false
      case .failure(let error):
        print(error)
        if !error.noInternetConnection /*&& self.hiddenAuthCompleted*/ {
          self.showErrorMessage(autohide: false)
          self.skeleton?.setError()
        }
      }
    }
  }

  @objc
  func streamsDidUpdate(_ notification: Notification) {
    guard let addedCount = notification.userInfo?["addedCount"] as? Int,
    let deleted = notification.userInfo?["deleted"] as? [Int],
    let hasChanges = notification.userInfo?["updated"] as? Bool, hasChanges else {
      skeleton?.loaded(videoContent: Live.self, isEmpty: dataSource.streams.isEmpty)
      updateVisibleCells()
      collectionView.collectionViewLayout.invalidateLayout()
      return
    }
    skeleton?.loaded(videoContent: Live.self, isEmpty: dataSource.streams.isEmpty)
    skeleton?.loaded(videoContent: VOD.self, isEmpty: dataSource.videos.isEmpty)
    reloadCollectionViewDataSource(addedCount: addedCount, deletedIndexes: deleted)
    bottomMessage.hideMessage()
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
    //MARK: wait 0.1 sec because visible cells is empty in moment notification triggering
    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) { [weak self] in
      self?.activeCell = self?.getTopVisibleCell()
    }
  }
  
  private func reloadCollectionViewDataSource(addedCount: Int, deletedIndexes: [Int]) {
    guard var visibleIndexPath = getTopVisibleRow(),
      var differenceBetweenRowAndNavBar = heightDifferenceBetweenTopRowAndNavBar() else {
        reachedListsEnd = false
      // MARK: merge to 1 line
        if skeleton == nil {
          if self.view.window != nil {
            self.activeCell = self.getTopVisibleCell()
          }
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

      let deletedPaths = deletedIndexes.map { IndexPath(item: $0, section: 0) }
      var addedPaths = [IndexPath]()
      for index in 0 ..< addedCount {
        addedPaths.append(IndexPath(item: index, section: 0))
      }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
      collectionView.performBatchUpdates({
        collectionView.deleteItems(at: deletedPaths)
        collectionView.insertItems(at: addedPaths)
      }, completion: { _ in
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.updateVisibleCells()
        if addedCount > 0, self.newLivesButton.isHidden {
          let shouldShow = visibleIndexPath.section == 1 || visibleIndexPath.item > 0
          self.newLivesButton.isHidden = !shouldShow
        } else if streamsCount == 0 {
          self.newLivesButton.isHidden = true
        }
        if shouldScroll {
          self.shouldResetActiveCell = false
          if !self.collectionView.isDecelerating {
            self.collectionView.scrollToItem(at: visibleIndexPath, at: .top, animated: false)
          }
          self.collectionView.contentOffset.y = self.collectionView.contentOffset.y - differenceBetweenRowAndNavBar
          self.shouldResetActiveCell = true
        }
        self.setActiveCell()
        CATransaction.commit()
      })
  }
  
  @objc
  private func didPullToRefresh(_ sender: Any) {
    if isDataSourceEmpty {
      // MARK: wierd
      skeleton?.collectionView?.delegate = skeleton
      skeleton?.collectionView?.dataSource = skeleton
    }
    skeleton?.startLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      if self?.isReachable == true {
        self?.bottomMessage.hideMessage()
      }
      self?.dataSource.updateVods { (result) in
        self?.refreshControl.endRefreshing()
        switch result {
        case .success:
          self?.reachedListsEnd = false
          self?.skeleton?.loaded(videoContent: VOD.self, isEmpty: self?.isDataSourceEmpty == true)
            self?.collectionView.reloadSections(IndexSet(arrayLiteral: 0, 1))

        case .failure(let error):
          if !error.noInternetConnection /*&& self?.hiddenAuthCompleted == true*/ {
            if self?.isReachable == true {
              self?.showErrorMessage(autohide: false)
              self?.skeleton?.setError()
            }
          }
        }
      }
    }
  }

  private func configureHeader() {
    if let currentInfo = HeaderInfoModel.currentInfo, let imadeData = currentInfo.imageData {
      tagLineLabel.text = currentInfo.tagLine
      logoImageView.image = UIImage(data: imadeData)
    }

    HeaderInfoModel.fetchInfo { [weak self] (info) in
      guard let info = info else {
        //TODO: show error
        return
      }
      self?.tagLineLabel.text = info.tagLine

      HeaderInfoModel.currentInfo?.imageData = nil
      if let urlString = info.imageUrl, let url = URL(string: urlString) {
        ImageService.downloadImage(withURL: url) { [weak self] (image) in
          self?.logoImageView.image = image
          HeaderInfoModel.currentInfo?.imageData = image?.pngData()
        }
      } else {
        self?.logoImageView.image = nil
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

  private func updateVisibleCells() {
    let visibleCells = collectionView.visibleCells.filter { self.collectionView.indexPath(for: $0)?.section == 0 }.compactMap { $0 as? StreamCell }
    visibleCells.forEach { (cell) in
      if let indexPath = self.collectionView.indexPath(for: cell) {
        self.configureCell(cell, forIndexPath: indexPath)
      }
    }
  }


  @discardableResult
  fileprivate func configureCell(_ cell: StreamCell, forIndexPath indexPath: IndexPath) -> StreamCell {
    let item = getItemWith(indexPath: indexPath)
    cell.joinButton.isHidden = item is VOD || !item.isChatOn
    cell.chatView.isHidden = true
    cell.pollView.isHidden = true
    cell.shareButton.isHidden = true
    cell.chatEnabled = item.isChatOn
    cell.message = item.latestMessage
    cell.titleLabel.text = item.title
    cell.subtitleLabel.text = "\(item.creatorNickname) • \(item.date.timeAgo())"
    cell.viewersCountLabel.text = item.viewsCount.formatUsingAbbrevation()
    cell.userImageView.load(url: URL(string: item.broadcasterPicUrl), placeholder: UIImage.image("avaPic"))
    cell.contentImageView.load(url: URL(string: item.thumbnailUrl), placeholder: UIImage.image("PlaceholderVideo"))
    cell.isLive = item is Live
    if let item = item as? VOD {
      cell.chatView.isHidden = item.latestMessage == nil
      cell.isNew = item.isNew
      cell.duration = item.duration.duration()
      //Temp solution
      let duration = item.stopTime.duration() == 0 ? nil : item.stopTime.duration()
      cell.watchedTime = item.isNew ? nil : duration
      cell.replayView.isHidden = true
    } else if let item = item as? Live {
      let duration = Date().timeIntervalSince(item.date)
      cell.duration = Int(duration)
      cell.chatView.isHidden = !(item.isChatOn || item.latestMessage != nil)
      cell.pollView.isHidden = !item.isPollOn
      cell.watchedTime = nil
      cell.replayView.isHidden = true
      cell.joinAction = { [weak self] itemCell in
        guard let indexPath = self?.collectionView.indexPath(for: itemCell) else { return }
        self?.openPlayer(indexPath: indexPath, shouldEnableChatField: true)
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
    let whereIsNavBarInTableView = collectionView.convert(headerView.bounds, from: headerView)
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
   let cell = collectionView.indexPathsForVisibleItems
    .sorted()
    .map { self.collectionView.cellForItem(at: $0 ) as? StreamCell }
    .first(where: {
      guard let cell = $0 else { return false }
      let cellRect = cell.frame
      var listRect = self.collectionView.bounds
      listRect.origin.y -= cellRect.height * 0.25
      listRect.size.height += cellRect.height * 0.4
      return listRect.contains(cellRect)
    })
    return cell as? StreamCell
  }

  private func showErrorMessage(autohide: Bool = true) {
    let color = UIColor.color("a_bottomMessageGray") ?? .gray
    let text = LocalizedStrings.generalError.localized.uppercased()
    if autohide {
      bottomMessage.showMessage(title: text, duration: 3, backgroundColor: color)
      return
    }
    bottomMessage.showMessage(title: text, backgroundColor: color)
  }

  fileprivate func openPlayer(indexPath: IndexPath, shouldEnableChatField: Bool = false) {
    let item = getItemWith(indexPath: indexPath)
    let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
    playerVC.videoContent = item
    playerVC.dataSource = dataSource
    playerVC.shouldEnableChatField = shouldEnableChatField
    // TODO: set temp stop time from list

    //temp solution
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) { [weak self] in
      guard let `self` = self, OrientationUtility.isLandscape else { return }
      self.collectionView.contentOffset = CGPoint(x: self.topInset, y: self.collectionView.contentOffset.y)
      self.collectionView.collectionViewLayout.invalidateLayout()
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
  private func fetchNextBunchOfVods() {
    guard !fetchingNextItems else { return }
    if dataSource.videos.count % 15 == 0 {
      let index = dataSource.videos.count
      self.fetchingNextItems = true
      self.failedToLoadVods = false
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
          self.failedToLoadVods = true
          if self.isReachable {
            self.showErrorMessage()
            print("Error fetching vods")
          }
        }
      }
    } else {
      reachedListsEnd = true
    }
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
    openPlayer(indexPath: indexPath)
  }
  
   func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard indexPath.section == 1, indexPath.row == dataSource.videos.count - 1, !isLoading else {
      return
    }
    fetchNextBunchOfVods()
  }
}

// MARK: UICollectionViewDelegateFlowLayout
extension StreamListController: UICollectionViewDelegateFlowLayout {
  func isItemExist(at indexPath: IndexPath) -> Bool {
    if indexPath.section == .zero {
      return dataSource.streams.indices.contains(indexPath.row)
    }
    return dataSource.videos.indices.contains(indexPath.row)
  }


  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    var height = view.bounds.width
    if isItemExist(at: indexPath) {
      let item = getItemWith(indexPath: indexPath)
      if let message = item.latestMessage?.text {
        let width = view.bounds.width - 40
        let labelHeight = message.height(withConstrainedWidth: width, font: .systemFont(ofSize: 12))
        height += labelHeight + 2 + 12 + 14.5
      }
      let isVod = item is VOD
      let hasLatestMessage = item.latestMessage != nil
      if (!isVod && (item.isChatOn || hasLatestMessage) || hasLatestMessage && isVod) || item.isPollOn || item.shareLink != nil {
        height += 12 + 0.075 * view.bounds.width
      }
      if item is Live, item.isChatOn {
        height += 20 + 12
      }
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
    case .loaded:
      UIView.animate(withDuration: 0.3, animations: {
        self.curtainThumbnail.alpha = 0
      }) { (_) in
        self.curtainThumbnail.removeFromSuperview()
        self.curtainThumbnail.alpha = 1
      }
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
        item.stopTime = min(Int(currentTime), item.duration.duration()).durationString()
      } else if let item = self?.activeItem as? Live {
        let duration = Date().timeIntervalSince(item.date)
        self?.activeCell?.duration = Int(duration)
        if self?.activeCell?.timeImageView.isAnimating == false {
          self?.activeCell?.timeImageView.startAnimating()
        }
      }
    }
  }

  public func modernAVPlayer(_ player: ModernAVPlayer, didItemDurationChange itemDuration: Double?) {
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      UIView.animate(withDuration: 0.1) {
        self.activeCell?.timeImageView.isHidden = false
      }
      if self.activeCell?.timeImageView.isAnimating == false {
        self.activeCell?.timeImageView.startAnimating()
      }
    }
  }

}

extension StreamListController: SkeletonDelegate {
  func skeletonWillHide(_ skeleton: Skeleton) {
    collectionView.delegate = self
    collectionView.dataSource = self
//    collectionView.isUserInteractionEnabled = true
  }
}
