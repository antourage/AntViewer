//
//  SkeletonCell.swift
//  AntViewer
//
//  Created by Maryan Luchko on 08.05.2020.
//

import UIKit
import AntViewerExt

class SkeletonCell: UICollectionViewCell {

  @IBOutlet var viewsToUpdateCornerRadius: [UIView]!
  @IBOutlet var iconImageView: UIImageView!
  @IBOutlet var loaderImageView: UIImageView!
  
  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    viewsToUpdateCornerRadius.forEach { (view) in
      view.layer.cornerRadius = view.bounds.height/2
    }
  }

}
