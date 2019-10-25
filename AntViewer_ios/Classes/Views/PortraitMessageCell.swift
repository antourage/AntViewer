//
//  PortraitMessageCell.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/7/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit

protocol MessageSupportable {
  var avatarImageView: CacheImageView! { get set }
  var nameLabel: UILabel! { get set }
  var messageLabel: UILabel! { get set }
}

class PortraitMessageCell: UITableViewCell, MessageSupportable {
  
  @IBOutlet weak var avatarImageView: CacheImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!
  
}
