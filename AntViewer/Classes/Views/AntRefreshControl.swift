//
//  AntRefreshControl.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 01.05.2020.
//

import UIKit

class AntRefreshControl: UIRefreshControl {

  private(set) var isRefreshControlAnimating = false

  private var startTopConstraint: NSLayoutConstraint?
  private var backgroundTopConstraint: NSLayoutConstraint?

  private lazy var refreshContainerView: UIView = {
    let containerView = UIView(frame: self.bounds)
    containerView.clipsToBounds = true
    tintColor = UIColor.clear
    addSubview(containerView)
    return containerView
  }()
  private lazy var startImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage.image("PullToUpdateStart00")
    refreshContainerView.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: refreshContainerView.centerXAnchor),
      imageView.heightAnchor.constraint(equalTo: refreshContainerView.heightAnchor)
    ])
    startTopConstraint = imageView.topAnchor.constraint(equalTo: refreshContainerView.topAnchor)
    startTopConstraint?.isActive = true
    return imageView
  }()
  private lazy var backgroundContainerView: UIView = {
    let view = UIView()
    refreshContainerView.addSubview(view)
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.bottomAnchor.constraint(equalTo: refreshContainerView.bottomAnchor),
      view.leadingAnchor.constraint(equalTo: refreshContainerView.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: refreshContainerView.trailingAnchor)
    ])
    backgroundTopConstraint = view.topAnchor.constraint(equalTo: refreshContainerView.topAnchor)
    backgroundTopConstraint?.isActive = true
    return view
  }()

  private var backgroundViews = [UIView]()
  private var isDragging = false
  var shouldAnimate = true

  required override public init() {
    fatalError("use init(frame:) instead")
  }

  required public init(coder aDecoder: NSCoder) {
    fatalError("use init(frame:) instead")
  }

  required override public init(frame: CGRect) {
    super.init()
    bounds.size.width = frame.size.width
    backgroundContainerView.isHidden = false
  }

  private func finishAnimation() {
    startImageView.isHidden = false
    startTopConstraint?.constant = 0
    refreshContainerView.layoutIfNeeded()
    backgroundViews.forEach {
      $0.layer.removeAllAnimations()
      $0.removeFromSuperview()
    }
    backgroundViews.removeAll()
    isRefreshControlAnimating = false
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    var refreshBounds = self.bounds
    let pullDistance = max(0.0, -self.frame.origin.y)
    let pullProgress = Int(min(pullDistance / 2, 24))
    if isDragging == false && frame.origin.y > -1 && isRefreshControlAnimating {
      finishAnimation()
    }
    refreshBounds.size.height = pullDistance
    self.refreshContainerView.frame = refreshBounds

    if !isRefreshing && !isRefreshControlAnimating {
      backgroundTopConstraint?.constant = pullDistance
      refreshContainerView.layoutIfNeeded()
      startImageView.image = UIImage.image(String(format: "PullToUpdateStart%02d", pullProgress))
    }

    if isRefreshing && !isRefreshControlAnimating && shouldAnimate {
      animateRefreshView()
    }
  }

  func animateRefreshView() {
    isRefreshControlAnimating = true
    backgroundTopConstraint?.constant = 0
    startTopConstraint?.constant = -300
    UIView.animate(withDuration: 0.5, animations: {
      self.refreshContainerView.layoutIfNeeded()
    }) { (value) in
      self.startImageView.isHidden = true
    }
    addBackgroundAnimation(with: "PullToUpdate2s", and: 2)
    addBackgroundAnimation(with: "PullToUpdate3s", and: 3)
    addBackgroundAnimation(with: "PullToUpdate6s", and: 6)
  }

  func addBackgroundAnimation(with imageName: String, and duration: TimeInterval) {

    let backgroundImage = UIImage.image(imageName)
    let animationOptions: UIView.AnimationOptions = [.repeat, .curveLinear]
    let width = refreshContainerView.bounds.width
    let height = width * 1.775

    let backgroundImageView1 = UIImageView(image: backgroundImage)
    backgroundImageView1.frame = CGRect(x: 0, y: 0, width: width, height: height)
    backgroundContainerView.addSubview(backgroundImageView1)

    let backgroundImageView2 = UIImageView(image: backgroundImage)
    backgroundImageView2.frame = CGRect(x: 0, y: height, width: width, height: height)
    backgroundContainerView.addSubview(backgroundImageView2)

    backgroundViews.append(contentsOf: [backgroundImageView1, backgroundImageView2])

    UIView.animate(withDuration: duration, delay: 0.0, options: animationOptions, animations: {
      backgroundImageView1.frame = backgroundImageView1.frame.offsetBy(dx: 0, dy: -1 * backgroundImageView1.frame.height)
      backgroundImageView2.frame = backgroundImageView2.frame.offsetBy(dx: 0, dy: -1 * backgroundImageView2.frame.height)
    }, completion: nil)
  }

}


