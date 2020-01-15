//
//  StreamListController.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/4/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AntViewerExt

private let reuseIdentifier = "NewStreamCell"

class StreamListController: UICollectionViewController {
  
  fileprivate var swiftMessage: SwiftMessage?
  fileprivate var cellWidth: CGFloat!
  fileprivate var cellHeight: CGFloat!
  fileprivate var isLoading = false {
    didSet {
      collectionView.isUserInteractionEnabled = !isLoading
      emptyDataSourceView?.isLoading = isLoading
      emptyDataSourceView?.isDataSourceEmpty = isDataSourceEmpty
    }
  }
  
  fileprivate var isStreamsLoaded = false {
    didSet {
      disableLoading()
    }
  }
  
  fileprivate var isVideosLoaded = false {
    didSet {
      disableLoading()
    }
  }
  
  fileprivate var isAllContentLoaded: Bool {
    isStreamsLoaded && isVideosLoaded
  }
  
  
  
  fileprivate var isDataSourceEmpty: Bool {
   return dataSource.videos.isEmpty && dataSource.streams.isEmpty
  }
  
  fileprivate var emptyDataSourceView: EmptyDataSourceView?
  
  var dataSource: DataSource!
  var isReadyToUpdate = false {
    didSet {
      reloadCollectionViewDataSource()
    }
  }
  
  private var isFetchingNextItems = false
  private var footerView: FooterView? {
    didSet {
      if let footerView = footerView {
        if isFetchingNextItems {
          footerView.activityIndicatorView.startAnimating()
        } else {
          footerView.activityIndicatorView.stopAnimating()
        }
      }
    }
  }
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
    collectionView.isUserInteractionEnabled = isReadyToUpdate
    emptyDataSourceView = EmptyDataSourceView(frame: collectionView.bounds)
    collectionView.backgroundView = emptyDataSourceView
    isLoading = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      self.isReadyToUpdate = true
    }
    
    initialVodsUpdate()
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "StreamsUpdated"), object: nil, queue: .main) { [weak self](notification) in
      self?.isStreamsLoaded = true
      self?.reloadCollectionViewDataSource()
    }
    
    refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
    collectionView.alwaysBounceVertical = true
    collectionView.refreshControl = refreshControl
    
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard isReadyToUpdate else { return }
    collectionView.reloadData()
  }
  
  deinit {
    print("StreamListController deinited.")
  }
  
  func initialVodsUpdate() {
    dataSource.updateVods { [weak self] (result) in
      guard let `self` = self else { return }
      self.isVideosLoaded = true
      switch result {
      case .success:
        self.reloadCollectionViewDataSource()
      case .failure(let error):
        print(error)
        if error.noInternetConnection || self.isHiddenAuthCompleted {
          self.swiftMessage?.showBanner(title: error.noInternetConnection ? "No internet connection" : error.localizedDescription )
        }
      }
    }
  }
  
  private func reloadCollectionViewDataSource() {
    guard isReadyToUpdate else { return }
    if !isDataSourceEmpty {
      isLoading = false
    } else {
      guard isAllContentLoaded else { return }
      collectionView.backgroundView = emptyDataSourceView
      emptyDataSourceView?.isDataSourceEmpty = true
    }
    collectionView.reloadData()
  }
  
  private func disableLoading() {
    guard isReadyToUpdate else { return }
    if isAllContentLoaded {
      isLoading = false
    }
  }
  
  private func setupNavigationBar() {
    navigationController?.navigationBar.barTintColor = collectionView.backgroundColor
    navigationController?.navigationBar.updateBackgroundColor()
    let closeButton = UIButton(type: .custom)
    closeButton.tintColor = .white
    closeButton.setImage(UIImage.image("cross"), for: .normal)
    
    closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
    closeButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
    
    navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: closeButton)]
    
    let changeHost = UIButton(type: .custom)
    changeHost.tintColor = .white
    changeHost.titleLabel?.font = changeHost.titleLabel?.font.withSize(10)
    changeHost.setTitle("", for: .normal)
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
        self?.swiftMessage?.showBanner(title: error.noInternetConnection ? "No internet connection" : error.localizedDescription )
      }
     
    }
  }
  
  private func setupCollectionView() {
    let cellNib = UINib(nibName: "NewStreamCell", bundle: Bundle(for: type(of: self)))
    collectionView.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
    let headerNib = UINib(nibName: "HeaderView", bundle: Bundle(for: type(of: self)))
    collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "AntHeaderView")
    let footerNib = UINib(nibName: "FooterView", bundle: Bundle(for: type(of: self)))
    collectionView.register(footerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "AntFooterView")
    cellWidth = view.bounds.width * 0.85
    cellHeight = cellWidth * 0.56
    collectionView.reloadData()
  }
  
  @objc
  private func changeHost(_ sender: UIButton, event: UIEvent) {
    guard let touches = event.allTouches?.first, touches.tapCount == 3 else {
      return
    }
    presentChangeHostAlert()
    if let version = Bundle(identifier: "org.cocoapods.AntWidget")?.infoDictionary?["CFBundleShortVersionString"] as? String {
      sender.setTitle(version, for: .normal)
      DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak sender] in
        sender?.setTitle(nil, for: .normal)
      }
    }
    
  }
  
  @objc
  private func closeButtonPressed(_ sender: UIButton) {
    onViewerDismiss?([:])
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ViewerWillDisappear"), object: nil)
    dataSource.startUpdatingVods()
    dismiss(animated: true, completion: { [weak self] in
      self?.dataSource.videos = []
    })
  }
  
  fileprivate func configureCell(_ cell: NewStreamCell, forIndexPath indexPath: IndexPath) -> NewStreamCell {
    let item = getItemForIndexPath(indexPath)
    cell.streamNameLabel.text = item.title
    cell.startTimeLabel.text = item.date.timeAgo()
    cell.liveLabel.isHidden = item is Vod
    if let item = item as? Vod {
      cell.startTimeLabel.text = item.date.addingTimeInterval(TimeInterval(item.duration.duration())).timeAgo()
      cell.viewersCountLabel.text = "\(item.viewsCount)"
      cell.videoDuration = item.duration
      cell.isContentNew = item.isNew
      cell.watchedTime = item.isNew ? 0 : item.stopTime.duration()
    } else if let item = item as? AntViewerExt.Stream {
      cell.isContentNew = false
      cell.watchedTime = 0
      cell.streamDurationView.isHidden = true
      cell.viewersCountLabel.text = "\(item.viewersCount)"
    }
    
    cell.imagePlaceholder.load(url: URL(string: item.thumbnailUrl), placeholder: UIImage.image("camera"))
    cell.layoutSubviews()
    return cell
  }
  
  fileprivate func getItemForIndexPath(_ indexPath: IndexPath) -> VideoContent {
    if dataSource.streams.isEmpty || dataSource.videos.isEmpty {
      return dataSource.streams.isEmpty ? dataSource.videos[indexPath.row] : dataSource.streams.reversed()[indexPath.row]
    } else {
      return indexPath.section == 0 ? dataSource.streams.reversed()[indexPath.row] : dataSource.videos[indexPath.row]
    }
  }
}


// MARK: UICollectionViewDataSource
extension StreamListController {
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    if !self.isReadyToUpdate {
      return 0
    }
    return dataSource.streams.isEmpty || dataSource.videos.isEmpty ? 1 : 2
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if !self.isReadyToUpdate {
      return 0
    }
    
    if !isDataSourceEmpty {
      collectionView.backgroundView = nil
    }
    if dataSource.streams.isEmpty || dataSource.videos.isEmpty {
      return dataSource.streams.isEmpty ? dataSource.videos.count : dataSource.streams.count
    }
    return section == 0 ? dataSource.streams.count : dataSource.videos.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! NewStreamCell
    return configureCell(cell, forIndexPath: indexPath)
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    
    switch kind {
    case UICollectionView.elementKindSectionHeader :
      let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "AntHeaderView", for: indexPath) as! HeaderView
      header.titleLabel.isHidden = indexPath.section != 0
      header.separatoView.isHidden = indexPath.section == 0
      
      if isDataSourceEmpty || isLoading {
        header.titleLabel.text = ""
      } else {
        if isReadyToUpdate {
        header.titleLabel.text = "Latest videos"
        }
      }
      return header
      
    case UICollectionView.elementKindSectionFooter :
      let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "AntFooterView", for: indexPath) as! FooterView
      self.footerView = footer
      return footer
    default:
      return UICollectionReusableView()
    }
  }
  
}

// MARK: UICollectionViewDelegate
extension StreamListController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard URLSessionNetworkDispatcher.instance.isReachable else {
      self.swiftMessage?.showBanner(title: "No internet connection" )
      return
    }
    let item = getItemForIndexPath(indexPath)
    let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
    playerVC.videoContent = item
    playerVC.dataSource = dataSource
    if item is Vod {
      let navController = PlayerNavigationController(rootViewController: playerVC)
      navController.modalPresentationStyle = .fullScreen
      return present(navController, animated: true, completion: nil)
    }
    playerVC.modalPresentationStyle = .fullScreen
    present(playerVC, animated: true, completion: nil)
  }
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    let vodsSection = dataSource.streams.count == 0 ? 0 : 1
    guard indexPath.section == vodsSection else { return }
    if indexPath.row == dataSource.videos.count - 1 && !isLoading, dataSource.videos.count % 15 == 0 {
      let index = dataSource.videos.count
      self.isFetchingNextItems = true
      dataSource.fetchNextItemsFrom(index: index) { [weak self] (result) in
        guard let `self` = self else { return }
        switch result {
        case .success :
          let count = self.dataSource.videos.count
          let vodsSection = self.dataSource.streams.count == 0 ? 0 : 1
          let indexPaths = (index..<count).map {IndexPath(row: $0, section: vodsSection)}
          self.collectionView.insertItems(at: indexPaths)
        case .failure(let error):
          self.swiftMessage?.showBanner(title: error.noInternetConnection ? "No internet connection" : error.localizedDescription )
          print("Error fetching vods")
        }
        self.isFetchingNextItems = false
      }
    }
  }
}

// MARK: UICollectionViewDelegateFlowLayout
extension StreamListController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: cellWidth, height: cellHeight)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    let sideInset = (collectionView.bounds.width - cellWidth)/2
    return UIEdgeInsets(top: 30, left: sideInset, bottom: 30, right: sideInset)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 30
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: section == 0 ? 50 : 1)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    let numberOfSections = collectionView.numberOfSections
    return CGSize(width: collectionView.bounds.width, height: section == (numberOfSections - 1) ? 30 : 1)
  }
}

