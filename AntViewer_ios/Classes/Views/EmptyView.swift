//
//  EmptyView.swift
//  AntViewer
//
//  Created by Mykola Vaniurskyi on 2/21/19.
//  Copyright © 2019 Antourage. All rights reserved.
//

import UIKit

public class EmptyView: UIView {
  
  let kCONTENT_XIB_NAME = "EmptyView"
  
  @IBOutlet var contentView: UIView!
  
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
