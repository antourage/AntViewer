//
//  EmptyDataSourceView.swift
//  AntViewer_ios
//
//  Created by Maryan Luchko on 10.10.2019.
//

import Foundation


public class EmptyDataSourceView: UIView {
  
  let kCONTENT_XIB_NAME = "EmptyDataSourceView"
  
  @IBOutlet var contentView: UIView!
  @IBOutlet private var logoImageView: UIImageView!

  var logoImage: UIImage? {
    didSet {
      logoImageView.image = logoImage
    }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit() {
    Bundle(for: type(of: self)).loadNibNamed(kCONTENT_XIB_NAME, owner: self, options: nil)
    contentView.fixInView(self)
  }
}
