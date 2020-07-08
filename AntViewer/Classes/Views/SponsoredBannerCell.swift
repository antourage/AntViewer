//
//  SponsoredBannerCell.swift
//  AntViewer
//
//  Created by Maryan Luchko on 08.07.2020.
//

import UIKit

class SponsoredBannerCell: UITableViewCell {
  @IBOutlet var sponsoredBannerImageView: CacheImageView!
  var onBannerTapped: (()->())?

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
