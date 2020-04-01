//
//  ViewController.swift
//  AntViewer_ios
//
//  Created by Mykola Vaniurskyi on 04/17/2019.
//  Copyright (c) 2019 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AntViewer

class ViewController: UIViewController {
  
  var widget: AntWidget! {
    didSet {
      view.addSubview(widget.view)
    }
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return [.portrait]
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    widget = AntWidget.shared
  }
  
}

