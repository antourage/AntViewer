//
//  Skeleton.swift
//  AntViewer
//
//  Created by Maryan Luchko on 13.05.2020.
//

import Foundation
import UIKit
import AntViewerExt

protocol SkeletonDelegate {
  func skeletonWillHide(_ skeleton: Skeleton)
  func skeletonOnTimeout(_ skeleton: Skeleton)
}

class Skeleton: NSObject {

  var delegate: SkeletonDelegate?
  var collectionView: UICollectionView? {
    didSet {
      collectionView?.delegate = self
      collectionView?.dataSource = self
      collectionView?.isUserInteractionEnabled = false
      let cellNib = UINib(nibName: String(describing: SkeletonCell.self), bundle: Bundle(for: type(of: self)))
      collectionView?.register(cellNib, forCellWithReuseIdentifier: "skeletonCell")
      collectionView?.reloadData()
    }
  }

  var cell: SkeletonCell? {
    didSet {
      guard let cell = cell else { return }
      animator = Animator(view: cell.loaderImageView, type: .spin)
      cell.layoutIfNeeded()
      initialUpdate()
    }
  }

  private lazy var emptyDataSourceView: EmptyDataSourceView = {
    let view = EmptyDataSourceView()

    return view
  }()

  private let loadingDebouncer = Debouncer(delay: 30)

  private var animator: Animator?

  private var isReachable = false

  enum SkeletonState {
    case noConnection, onError, emptyDataSource, loading
  }

  private var state: SkeletonState = .loading

  private func initialUpdate() {
    switch state {
    case .loading:
      startLoading()
    case .onError:
      setError()
    case .emptyDataSource:
      setEmptyDataSourseViewVisible(visible: true)
    case .noConnection:
      didChangeReachability(isReachable)
    }
  }

  var isVODLoaded: (isLoaded: Bool, isEmpty: Bool) = (false, false) {
    didSet {
      didUpdateState()
    }
  }

  var isLiveLoaded: (isLoaded: Bool, isEmpty: Bool) = (false, false)  {
    didSet {
      didUpdateState()
    }
  }

  private func didUpdateState() {
    if isVODLoaded.isLoaded {
      if !isVODLoaded.isEmpty {
        resetView()
        return
      }
    }

    if isLiveLoaded.isLoaded {
      if !isLiveLoaded.isEmpty {
        resetView()
        return
      }
    }

    guard isVODLoaded.isLoaded, isLiveLoaded.isLoaded else { return }
    if isVODLoaded.isEmpty, isLiveLoaded.isEmpty, isReachable {
      animator?.stop(immediately: true)
      setEmptyDataSourseViewVisible(visible: true)
      state = .emptyDataSource
    }
  }

  private func resetView() {
    animator?.stop(immediately: true)
    loadingDebouncer.call {}
    delegate?.skeletonWillHide(self)
  }

  func loaded(videoContent: VideoContent.Type, isEmpty: Bool) {
    switch videoContent {
    case is Live.Type:
      isLiveLoaded = (true, isEmpty)
    case is VOD.Type:
      isVODLoaded = (true, isEmpty)
    default:
      break
    }
  }

  func didChangeReachability(_ isReachable: Bool) {
    guard collectionView?.backgroundView == nil else { return }
    self.isReachable = isReachable
    if isReachable {
      startLoading()
    } else {
      state = .noConnection
      animator?.stop(immediately: false)
      cell?.iconImageView.image = UIImage.image("SkeletonNoConnection")
      collectionView?.isUserInteractionEnabled = true
    }
  }

  func startLoading() {
    guard isReachable else {
      didChangeReachability(isReachable)
      return
    }
    state = .loading
    collectionView?.isUserInteractionEnabled = false
    cell?.iconImageView.image = UIImage.image("SkeletonPlaceholder")
    cell?.loaderImageView.image = UIImage.image("SkeletonLoader")
    if animator?.isActive == false {
      animator?.animate(repeatCount: .infinity)
    }
    setEmptyDataSourseViewVisible(visible: false)
    loadingDebouncer.call { [weak self] in
      guard let `self` = self else { return }
      self.setError()
      self.delegate?.skeletonOnTimeout(self)
    }
  }

  func setError() {
    animator?.stop(immediately: false)
    cell?.iconImageView.image = UIImage.image("SkeletonError")
    collectionView?.isUserInteractionEnabled = true
    state = .onError
  }

  private func setEmptyDataSourseViewVisible(visible: Bool) {
    collectionView?.isUserInteractionEnabled = visible
    cell?.contentView.alpha = visible ? 0 : 1
    collectionView?.backgroundView = visible ? emptyDataSourceView : nil
  }

  deinit {
    print("Skeleton: DEINITED")
  }

}

extension Skeleton: UICollectionViewDelegate, UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    2
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return section == 0 ? 1 : 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "skeletonCell", for: indexPath) as! SkeletonCell
    self.cell = cell
    return cell
  }
}

extension Skeleton: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: 500)
  }
}

extension Skeleton: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    (collectionView?.refreshControl as? AntRefreshControl)?.scrollViewDidScroll(scrollView)
  }
}
