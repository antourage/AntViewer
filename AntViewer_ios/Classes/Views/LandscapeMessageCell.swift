//
//  LandscapeMessageCell.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/10/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit

class LandscapeMessageCell: UITableViewCell, MessageSupportable {
  
  @IBOutlet weak var avatarImageView: CacheImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!
  
}
