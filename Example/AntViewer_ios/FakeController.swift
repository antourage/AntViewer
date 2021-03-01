//
//  FakeController.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/14/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import Antourage

class FakeController: UIViewController {
  
  var widget: Antourage! {
    didSet {
      view.addSubview(widget.view)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    widget = Antourage.shared
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return [.portrait]
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
      .lightContent
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setNeedsStatusBarAppearanceUpdate()
  }
}
