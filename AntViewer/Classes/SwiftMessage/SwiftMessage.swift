//
//  SwiftMessage.swift
//  BanerMessage
//
//  Created by Maryan Luchko on 12.12.2019.
//  Copyright © 2019 Maryan Luchko. All rights reserved.
//

import Foundation
import UIKit

class SwiftMessage {
  
//  static let shared = SwiftMessage()
//  private init() {}
  
  init(presentingController: UIViewController){
    self.presenter = presentingController
  }
  
  weak var presenter: UIViewController?
  
  private var timer: Timer?
  private var currentBanner: MessageView? {
    didSet {
      guard let bannerView = currentBanner, let presenter = presenter else {
        timer?.invalidate()
        timer = nil
        return
      }

      presenter.view.addSubview(bannerView)
      bannerView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint(item: bannerView, attribute: .leading, relatedBy: .equal, toItem: presenter.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
      NSLayoutConstraint(item: bannerView, attribute: .trailing, relatedBy: .equal, toItem: presenter.view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
      
      
      bannerView.showAnimation()
      bannerView.shouldHide = { [weak self] in
        self?.resetCurrentBanner()
      }

      timer = Timer.scheduledTimer(withTimeInterval: bannerView.presentingDuration, repeats: false) { [weak self] (timer) in
        self?.currentBanner?.hideAnimation()
      }
    }
  }
  
  private var bannersQueue: [MessageView] = []
  private func resetCurrentBanner() {
    timer?.invalidate()
    timer = nil
    if !self.bannersQueue.isEmpty {
      self.currentBanner = nil
      self.currentBanner = self.bannersQueue.removeFirst()
    } else {
      self.currentBanner = nil
    }
  }
  
  func clearQueue() {
    bannersQueue.removeAll()
  }
  
  func forceHide() {
    clearQueue()
    currentBanner?.hideAnimation()
  }
  
  func showBanner(title: String, titleSize: CGFloat = 17, subtitleSize: CGFloat = 15, subtitle: String? = nil, duration: Double = 3, style: Theme = .error) {
    guard let vc = presenter else { return }
    forceHide()
    let bannerView = MessageView(withBanerHeight: 100, width: vc.view.bounds.width)
       bannerView.titleLabel?.textAlignment = .center
       bannerView.titleLabel?.numberOfLines = 0
       bannerView.titleLabel?.font = UIFont.systemFont(ofSize: titleSize)
        
       bannerView.bodyLabel.numberOfLines = 0
       bannerView.bodyLabel?.textAlignment = .center
       bannerView.bodyLabel?.font = UIFont.systemFont(ofSize: subtitleSize)
      
       bannerView.titleLabel.text = title
       bannerView.bodyLabel.text = subtitle
       bannerView.applyTheme(style)
  
       bannerView.presentingDuration = duration

      if currentBanner == nil {
        currentBanner = bannerView
      } else {
        bannersQueue.append(bannerView)
      }
  }
}
