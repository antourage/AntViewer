//
//  SponsoredBannerCell.swift
//  AntViewer
//
//  Created by Maryan Luchko on 08.07.2020.
//

import UIKit

class SponsoredBannerCell: UITableViewCell {
  @IBOutlet var sponsoredBannerImageView: CacheImageView!
  @IBOutlet var imageViewAspectRatio: NSLayoutConstraint!
  @IBOutlet var imageViewWidth: NSLayoutConstraint!
  var onBannerTapped: (()->())?

  func updateAspectRatioTo(_ newValue: CGFloat) {
    let newConstraint = NSLayoutConstraint(
      item: imageViewAspectRatio.firstItem,
      attribute: imageViewAspectRatio.firstAttribute,
      relatedBy: imageViewAspectRatio.relation,
      toItem: imageViewAspectRatio.secondItem,
      attribute: imageViewAspectRatio.secondAttribute,
      multiplier: newValue,
      constant: imageViewAspectRatio.constant)
    newConstraint.priority = imageViewAspectRatio.priority

    NSLayoutConstraint.deactivate([imageViewAspectRatio])
    imageViewAspectRatio = newConstraint
    NSLayoutConstraint.activate([imageViewAspectRatio])
    imageViewWidth.isActive = newValue == CGFloat(320)/50
  }

  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bannerDidTap(_:)))
    sponsoredBannerImageView.addGestureRecognizer(tapGesture)
  }

  @objc
  func bannerDidTap(_ sender: UITapGestureRecognizer) {
    onBannerTapped?()
  }
}
