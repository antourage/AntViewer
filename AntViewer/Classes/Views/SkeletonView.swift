//
//  SkeletonView.swift
//  AntViewer
//
//  Created by Maryan Luchko on 08.05.2020.
//

import UIKit
import AntViewerExt

class SkeletonView: UIView {

  @IBOutlet private var contentView: UIView!
  @IBOutlet private var viewsToUpdateCornerRadius: [UIView]!
  @IBOutlet private var iconImageView: UIImageView!
  @IBOutlet private var emptyDataSourceView: UIView!
  private let loadingDebouncer = Debouncer(delay: 30)
  @IBOutlet var topConstraint: NSLayoutConstraint!

  private lazy var animator: Animator =  {
   let animator = Animator(view: iconImageView, type: .spin)
    return animator
  }()

  var completion: (() -> ())?
  var onTimeout: (() -> ())?

  private var isReachable = false

  enum SkeletonState {
    case noConnection, onError, emptyDataSource
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

    if isVODLoaded.isEmpty, isLiveLoaded.isEmpty, isReachable {
      animator.stop(immediately: true)
      emptyDataSourceView.isHidden = false
      layoutIfNeeded()
    }
  }

  private func resetView() {
    animator.stop(immediately: true)
    loadingDebouncer.call {}
    completion?()
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
    guard emptyDataSourceView.isHidden else { return }
    self.isReachable = isReachable
    if isReachable {
      startLoading()
    } else {
      animator.stop(immediately: true)
      iconImageView.image = UIImage.image("PlaceholderNoConnection")
    }
  }

  func startLoading() {
    iconImageView.image = UIImage.image("SkeletonLoader")
    animator.animate(repeatCount: .infinity)
    emptyDataSourceView.isHidden = true
    loadingDebouncer.call { [weak self] in
      self?.setError()
      self?.onTimeout?()
    }
  }

  func setError() {
    animator.stop(immediately: true)
    iconImageView.image = UIImage.image("SkeletonError")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    Bundle(for: type(of: self)).loadNibNamed(String(describing: SkeletonView.self), owner: self, options: nil)
    contentView.fixInView(self)
  }

  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    viewsToUpdateCornerRadius.forEach { (view) in
      view.layer.cornerRadius = view.bounds.height/2
    }
  }

}
