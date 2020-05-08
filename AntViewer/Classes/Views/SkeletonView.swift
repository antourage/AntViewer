//
//  SkeletonView.swift
//  AntViewer
//
//  Created by Maryan Luchko on 08.05.2020.
//

import UIKit

class SkeletonView: UIView {

  @IBOutlet var contentView: UIView!
  @IBOutlet var viewsToUpdateCornerRadius: [UIView]!

  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    Bundle(for: type(of: self)).loadNibNamed("SkeletonView", owner: self, options: nil)
    contentView.fixInView(self)
  }

  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    viewsToUpdateCornerRadius.forEach { (view) in
      view.layer.cornerRadius = view.bounds.width
    }
  }

}
