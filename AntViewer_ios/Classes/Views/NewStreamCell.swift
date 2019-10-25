//
//  CollectionViewCell.swift
//  controllers fot kolya
//
//  Created by Maryan Luchko on 12/17/18.
//  Copyright © 2018 Maryan Luchko. All rights reserved.
//

import UIKit

public class NewStreamCell: UICollectionViewCell {
  
  var gradientLayer: CAGradientLayer = {
    let gradient = CAGradientLayer()
    gradient.colors = [UIColor.black.withAlphaComponent(0.8).cgColor, UIColor.black.withAlphaComponent(0.1).cgColor, UIColor.black.withAlphaComponent(0.1).cgColor, UIColor.black.withAlphaComponent(0.85).cgColor]
    gradient.locations = [0, 0.3, 0.7, 1]
    return gradient
  }()
  
  @IBOutlet weak var liveLabel: UILabel!
  @IBOutlet weak var startTimeLabel: UILabel!
  @IBOutlet weak var streamDurationLabel: UILabel!
  @IBOutlet weak var viewersCountLabel: UILabel!
  @IBOutlet weak var imagePlaceholder: CacheImageView!
  @IBOutlet weak var streamNameLabel: UILabel!
  @IBOutlet weak var startTimeView: UIView!
  @IBOutlet weak var streamDurationView: UIView!
  @IBOutlet weak var gradientView: UIView! {
    didSet {
      //      gradientView.layer.addSublayer(gradientLayer)
      //      gradientLayer.frame = gradientView.bounds
    }
  }
  @IBOutlet private weak var watchedTimeLineViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet private weak var watchedTimeLinePaddingView: UIView!
  
  @IBOutlet private weak var newContentView: UIView!
  
  public var watchedTime = 0 {
    didSet {
      guard watchedTime > 0 else {
        watchedTimeLinePaddingView.isHidden = true
        return
      }
      watchedTimeLinePaddingView.isHidden = false
      guard let duration = streamDurationLabel.text?.duration() else { return }
      watchedTimeLineViewWidthConstraint.constant = (CGFloat(watchedTime) / CGFloat(duration)) * bounds.width
    }
  }
  
  public var isContentNew = false {
    didSet {
      self.newContentView.isHidden = !isContentNew
    }
  }
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    //FIXME: Gradient updates with delay
    //    gradientLayer.frame = gradientView.bounds
  }
}
