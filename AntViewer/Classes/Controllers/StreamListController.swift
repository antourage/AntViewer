//
//  StreamListController.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/4/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AVKit
import AntViewerExt

private let reuseIdentifier = "NewStreamCell"

class StreamListController: UICollectionViewController {
  
  fileprivate var cellWidth: CGFloat!
  fileprivate var cellHeight: CGFloat!
  fileprivate var isLoading = false {
    didSet {
      emptyDataSourceView?.isLoading = isLoading
    }
  }
  
  fileprivate var isDataSourceEmpty: Bool {
   return dataSource.videos.isEmpty && dataSource.streams.isEmpty
  }
  
  fileprivate var emptyDataSourceView: EmptyDataSourceView?
  
  var dataSource: DataSource!
  var isReadyToUpdate = false {
    didSet {
      isLoading = !isReadyToUpdate
      collectionView.isUserInteractionEnabled = isReadyToUpdate
      collectionView.reloadData()
    }
  }
  
  private let refreshControl = UIRefreshControl()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationBar()
    setupCollectionView()
    collectionView.isUserInteractionEnabled = isReadyToUpdate
    emptyDataSourceView = EmptyDataSourceView(frame: collectionView.bounds)
    collectionView.backgroundView = emptyDataSourceView
    isLoading = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      self.isReadyToUpdate = true
    }
    
    dataSource.updateVods { [weak self] (result) in
      guard let `self` = self else { return }
      switch result {
      case .success:
        guard self.isReadyToUpdate else { return }
        self.isLoading = false
        self.collectionView.reloadData()
      case .failure(let error):
        print(error)
      }
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "StreamsUpdated"), object: nil, queue: .main) { [weak self](notification) in
      guard let `self` = self, self.isReadyToUpdate else { return }
      self.isLoading = false
      
      if self.isDataSourceEmpty {
        self.collectionView.backgroundView = self.emptyDataSourceView
      } else {
        self.collectionView.reloadData()
        
      }
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
    
    changeHost.setTitle("", for: .normal)

    let gestureRec = UITapGestureRecognizer(target: self, action:  #selector(changeHost(_:)))
    gestureRec.numberOfTapsRequired = 3
    changeHost.addGestureRecognizer(gestureRec)
    changeHost.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
    
    navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: changeHost)]
  }
  
  @objc
  private func didPullToRefresh(_ sender: Any) {
    dataSource.updateVods { [weak self] (result) in
      self?.refreshControl.endRefreshing()
      self?.collectionView.reloadData()
      
    }
  }
  
  private func setupCollectionView() {
    let cellNib = UINib(nibName: "NewStreamCell", bundle: Bundle(for: type(of: self)))
    collectionView.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
    let headerNib = UINib(nibName: "HeaderView", bundle: Bundle(for: type(of: self)))
    collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "AntHeaderView")
    cellWidth = view.bounds.width * 0.85
    cellHeight = cellWidth * 0.56
    collectionView.reloadData()
  }
  
  @objc
  private func changeHost(_ sender: UIButton) {
    presentChangeHostAlert()
  }
  
  @objc
  private func closeButtonPressed(_ sender: UIButton) {
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ViewerWillDisappear"), object: nil)
    dismiss(animated: true, completion: { [weak self] in
      self?.dataSource.videos = []
    })
  }
  
  fileprivate func configureCell(_ cell: NewStreamCell, forIndexPath indexPath: IndexPath) -> NewStreamCell {
    let item = getItemForIndexPath(indexPath)
    cell.streamNameLabel.text = item.title
    cell.liveLabel.isHidden = item is Vod
    cell.startTimeLabel.text = item.date.timeAgo()
    if let item = item as? Vod {
      cell.viewersCountLabel.text = "\(item.viewsCount) views"
      cell.streamDurationLabel.text = item.duration
      cell.isContentNew = item.isNew
      cell.watchedTime = item.isNew ? 0 : item.stopTime.duration()
    } else if let item = item as? AntViewerExt.Stream {
      cell.isContentNew = false
      cell.watchedTime = 0
      cell.streamDurationView.isHidden = true
      cell.viewersCountLabel.text = "\(item.viewersCount) Viewers"
    }
    
    cell.imagePlaceholder.load(url: URL(string: item.thumbnailUrl), placeholder: UIImage.image("camera"))
    cell.layoutSubviews()
    return cell
  }
  
  fileprivate func getItemForIndexPath(_ indexPath: IndexPath) -> VideoContent {
    if dataSource.streams.isEmpty || dataSource.videos.isEmpty {
      return dataSource.streams.isEmpty ? dataSource.videos[indexPath.row] : dataSource.streams[indexPath.row]
    } else {
      return indexPath.section == 0 ? dataSource.streams[indexPath.row] : dataSource.videos[indexPath.row]
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
    guard kind == UICollectionView.elementKindSectionHeader else {
      return UICollectionReusableView()
    }
    let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "AntHeaderView", for: indexPath) as! HeaderView
    header.titleLabel.isHidden = indexPath.section != 0
    header.separatoView.isHidden = indexPath.section == 0
    
    if isDataSourceEmpty || isLoading {
      header.titleLabel.text = ""
    } else {
      if isReadyToUpdate {
      header.titleLabel.text = "Latest Videos"
      }
    }

    return header
  }
  
}

// MARK: UICollectionViewDelegate
extension StreamListController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//    guard !isDataSourceEmpty && !isLoading else { return }
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
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    let vodsSection = dataSource.streams.count == 0 ? 0 : 1
    guard indexPath.section == vodsSection else { return }
    if indexPath.row == dataSource.videos.count - 1 && !isLoading {
      dataSource.fetchNextItemsFrom(index: dataSource.videos.count) { [weak self] (result) in
        switch result {
        case .success :
          self?.collectionView.reloadData()
          break
        case .failure:
          //TODO: handle error
          print("Error fetching vods")
          break
        }
      }
    }
  }
  
}
