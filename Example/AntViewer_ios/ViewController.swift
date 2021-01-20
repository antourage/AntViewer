//
//  ViewController.swift
//  AntViewer_ios
//
//  Created by Mykola Vaniurskyi on 04/17/2019.
//  Copyright (c) 2019 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import Antourage

class ViewController: UIViewController {
  
  var widget: Antourage! {
    didSet {
      view.addSubview(widget.view)
    }
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return [.portrait]
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    widget = Antourage.shared
    widget.widgetPosition = .midLeft
    widget.widgetLocale = .swedish
//    widget.widgetMargins = AntMargins(vertical: 0, horizontal: 0)
  }
  
}

