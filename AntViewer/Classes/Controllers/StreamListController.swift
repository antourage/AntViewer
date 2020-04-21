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
  
  fileprivate var swiftMessage: SwiftMessage?
  fileprivate var isLoading = false {
    didSet {
      collectionView.isUserInteractionEnabled = !isLoading
    }
  }
  
  fileprivate var isDataSourceEmpty: Bool {
    return dataSource.videos.isEmpty && dataSource.streams.isEmpty
  }

  var dataSource: DataSource!
  
  private var isFetchingNextItems = false
  private var footerView: FooterView? {
    didSet {
      footerView?.jumpAction = { [weak self] in
        self?.scrollToTop()
      }
      footerView?.showButton = reachedListsEnd
      if isFetchingNextItems {
        footerView?.startAnimating()
      } else {
        footerView?.stopAnimating()
      }
    }
  }

  fileprivate var reachedListsEnd = false

  private let refreshControl = UIRefreshControl()
  private var isHiddenAuthCompleted = false
  
  var onViewerDismiss: ((NSDictionary) -> Void)?

  override func viewDidLoad() {
    super.viewDidLoad()
    AntViewerManager.shared.hiddenAuthIfNeededWith { [weak self] (result) in
      self?.isHiddenAuthCompleted = true
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
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "StreamsUpdated"), object: nil, queue: .main) { [weak self](notification) in
      self?.reloadCollectionViewDataSource()
    }
    
    refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
    collectionView.alwaysBounceVertical = true
    collectionView.refreshControl = refreshControl
    
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionView.reloadData()
  }

  func scrollToTop() {
    collectionView.setContentOffset(.zero, animated: true)
  }
  
  func initialVodsUpdate() {
    dataSource.updateVods { [weak self] (result) in
      guard let `self` = self else { return }
      switch result {
      case .success:
        self.reloadCollectionViewDataSource()
      case .failure(let error):
        print(error)
        if error.noInternetConnection || self.isHiddenAuthCompleted {
          self.swiftMessage?.showBanner(title: error.noInternetConnection ? "No internet connection available" : error.localizedDescription )
        }
      }
    }
  }
  
  private func reloadCollectionViewDataSource() {
    if !isDataSourceEmpty {
      isLoading = false
    }
    collectionView.reloadData()
  }
  
  private func setupNavigationBar() {
    //    navigationController?.navigationBar.frame =
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
    dataSource.updateVods { [weak self] (result) in
      self?.refreshControl.endRefreshing()
      switch result {
      case .success:
        self?.collectionView.reloadData()
      case .failure(let error):
        self?.swiftMessage?.showBanner(title: error.noInternetConnection ? "No internet connection available" : error.localizedDescription )
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
    presentChangeHostAlert()
//    if let version = Bundle(identifier: "org.cocoapods.AntWidget")?.infoDictionary?["CFBundleShortVersionString"] as? String {
//      sender.setTitle(version, for: .normal)
//      DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak sender] in
//        sender?.setTitle(nil, for: .normal)
//      }
//    }
    
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
    cell.subtitleLabel.text = "\(item.creatorNickname) • \(item.date.timeAgo())"
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
      cell.watchedTime = item.isNew ? 0 : item.stopTime.duration()
      cell.duration = item.duration.duration()
      //TODO: if active cell ended
      cell.replayView.isHidden = true
    } else if let item = item as? Live {
      cell.isLive = true
      cell.watchedTime = 0
      let duration = Date().timeIntervalSince(item.date)
      cell.duration = Int(duration)
      cell.replayView.isHidden = true
      cell.joinAction = { itemCell in
        //TOD: open player with field
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

     func getTopVisibleRow () -> IndexPath? {
         //We need this to accounts for the translucency below the nav bar
         let navBar = navigationController?.navigationBar
         let whereIsNavBarInTableView = collectionView.convert(navBar!.bounds, from: navBar)
         let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height + 1)
         let accurateIndexPath = collectionView.indexPathForItem(at: pointWhereNavBarEnds)
         return accurateIndexPath
     }

     func heightDifferenceBetweenTopRowAndNavBar() -> CGFloat? {
      let rectForTopRow = collectionView.layoutAttributesForItem(at: getTopVisibleRow()!)!.frame
         let navBar = navigationController?.navigationBar
         let whereIsNavBarInTableView = collectionView.convert(navBar!.bounds, from: navBar)
         let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height)
         let differenceBetweenTopRowAndNavBar = rectForTopRow.origin.y - pointWhereNavBarEnds.y
         return differenceBetweenTopRowAndNavBar
     }
}


// MARK: UICollectionViewDataSource
extension StreamListController {
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    //TODO: skeleton
    if false {
      return 1
    }
    
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
    guard URLSessionNetworkDispatcher.instance.isReachable else {
      self.swiftMessage?.showBanner(title: "No internet connection available" )
      return
    }
    let item = getItemWith(indexPath: indexPath)
    let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
    playerVC.videoContent = item
    playerVC.dataSource = dataSource
    if item is VOD {
      let navController = PlayerNavigationController(rootViewController: playerVC)
      navController.modalPresentationStyle = .fullScreen
      return present(navController, animated: true, completion: nil)
    }
    playerVC.modalPresentationStyle = .fullScreen
    present(playerVC, animated: true, completion: nil)
  }
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard indexPath.section == 1, indexPath.row == dataSource.videos.count - 1, !isLoading else {
      self.footerView?.isHidden = true
      return
    }
    if dataSource.videos.count % 15 == 0 {
      let index = dataSource.videos.count
      self.isFetchingNextItems = true
      self.footerView?.isHidden = false
      dataSource.fetchNextItemsFrom(index: index) { [weak self] (result) in
        guard let `self` = self else { return }
        switch result {
        case .success :
          let count = self.dataSource.videos.count
          let indexPaths = (index..<count).map {IndexPath(row: $0, section: 1)}
          self.collectionView.insertItems(at: indexPaths)
        case .failure(let error):
          self.swiftMessage?.showBanner(title: error.noInternetConnection ? "No internet connection available" : error.localizedDescription )
          print("Error fetching vods")
        }
        self.isFetchingNextItems = false
        self.footerView?.isHidden = true
      }
    } else {
      reachedListsEnd = true
      self.footerView?.isHidden = false
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
    if reachedListsEnd {
      return size
    }
    guard !isFetchingNextItems, !self.isLoading else {
      return .zero
    }
    return size
  }
}

