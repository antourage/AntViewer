//
//  StreamViewCell.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/4/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit

public class StreamViewCell: UICollectionViewCell {
  
  @IBOutlet public weak var liveView: UIView!
  @IBOutlet public weak var titleLabel: UILabel!
  @IBOutlet public weak var subtitleLabel: UILabel!
  @IBOutlet public weak var viewersCountLabel: UILabel!
  @IBOutlet public weak var timeLabel: UILabel!
  @IBOutlet public weak var contentImageView: UIImageView!
  
}
