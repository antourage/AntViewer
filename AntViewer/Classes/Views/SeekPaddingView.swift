//
//  SeekPaddingView.swift
//  AntViewer_ios-AntWidget
//
//  Created by Maryan Luchko on 09.10.2019.
//

import Lottie
import UIKit
import AntViewerExt

public class SeekPaddingView: UIView {
  
  public init(showInView view: UIView ) {
    self.parentView = view
    self.superviewFrame = view.bounds
    super.init(frame: view.bounds)
  }
  
  override public init(frame: CGRect) {
    self.parentView = UIView()
    self.superviewFrame = frame
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    self.parentView = UIView()
    self.superviewFrame = .zero
    super.init(coder: aDecoder)
  }
  
  private var parentView: UIView
  private var superviewFrame: CGRect
  private var customLayer: CAShapeLayer?
  private var seekView: UIView? {
    didSet {
      guard let seekView = seekView else { return }
      seekView.clipsToBounds = true
      seekView.isUserInteractionEnabled = false
    }
  }
  private var isLastSeekBackward: Bool?
  private var animationView: AnimationView? {
    didSet {
      guard let animationView = animationView else { return }
      seekView?.addSubview(animationView)
    }
  }
  private var seekTimeLabel: UILabel?
  
  public var soughtTime = 0 {
    didSet {
      guard soughtTime > 0, let label = seekTimeLabel else { return }
      label.text = String(format: "%d seconds", soughtTime)
    }
  }
  
  private var changeColorDebouncer = Debouncer(delay: 0.15)
  private var currentAlphaCoef: CGFloat = 0.3 {
    didSet {
      guard let customLayer = customLayer else { return }
      customLayer.fillColor = UIColor.black.withAlphaComponent(currentAlphaCoef).cgColor
    }
  }
  
  
  
  public func seekBackward() {
    if isLastSeekBackward ?? false {
      updateCustomLayerColor()
      self.animationView?.play()
      return
    }
    soughtTime = 0
    seekView?.removeFromSuperview()
    seekView = nil
    self.seekView = UIView(frame: CGRect(x: 0, y: 0, width: (superviewFrame.width / 2) * 0.8, height: superviewFrame.height))
    let path = self.drawPath(isBackward: true)
    addCustomLayer(withPath: path)
    addAnimation(isBackward: true)
    addSeekTimeLabel()
    parentView.addSubview(self.seekView!)
    animationView?.play()
    isLastSeekBackward = true
  }
  
  deinit {
    self.seekView?.removeFromSuperview()
  }
  
  public func seekForward() {
    if !(isLastSeekBackward ?? true) {
      updateCustomLayerColor()
      self.animationView?.play()
      return
    }
    soughtTime = 0
    seekView?.removeFromSuperview()
    seekView = nil
    self.seekView = UIView(frame: CGRect(x: superviewFrame.width - ((superviewFrame.width / 2) * 0.8), y: 0, width: (superviewFrame.width / 2) * 0.8, height: superviewFrame.height))
    let path = self.drawPath(isBackward: false)
    addCustomLayer(withPath: path)
    addAnimation(isBackward: false)

    
    addSeekTimeLabel()
    parentView.addSubview(self.seekView!)
    animationView?.play()
    isLastSeekBackward = false
  }
  
  private func addSeekTimeLabel() {
    self.seekTimeLabel = UILabel()
    self.seekTimeLabel?.frame.size = CGSize(width: self.seekView?.bounds.width ?? 0, height: 20)
    self.seekTimeLabel?.center.x = animationView?.center.x ?? 0
    self.seekTimeLabel?.center.y = (animationView?.frame.origin.y ?? 0) + (animationView?.frame.height ?? 0)
    self.seekTimeLabel?.textAlignment = .center
    self.seekTimeLabel?.textColor = UIColor.white
    self.seekView?.addSubview(seekTimeLabel!)
  }
  
  private func addCustomLayer(withPath path: UIBezierPath) {
    self.customLayer = CAShapeLayer()
    self.customLayer?.frame = seekView?.bounds ?? .zero
    self.customLayer?.path = path.cgPath
    self.customLayer?.fillColor = UIColor.black.withAlphaComponent(currentAlphaCoef).cgColor
    self.seekView?.layer.addSublayer(self.customLayer!)
  }
  
  private func addAnimation(isBackward: Bool) {
    //animation
    let podBundle = Bundle(for: AntWidget.self)
    guard let url = podBundle.url(forResource: "AntWidget", withExtension: "bundle"),
      let bundle = Bundle(url: url) else { return }
    let animation = isBackward ? "SkipB" : "SkipF"
    let animationView = AnimationView(name: animation, bundle: bundle)
    animationView.loopMode = .playOnce
    guard let view = seekView else { return }
    animationView.frame = CGRect(x: 0, y: 0, width: 70, height: 50)
    animationView.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
    self.animationView = animationView
    //
  }
  
  private func updateCustomLayerColor() {
    self.currentAlphaCoef = self.currentAlphaCoef + 0.15 > 0.5 ? 0.5 : self.currentAlphaCoef + 0.15
    changeColorDebouncer.call { [weak self] in
      guard let `self` = self else { return }
      self.currentAlphaCoef = self.currentAlphaCoef - 0.15 < 0.3 ? 0.3 : self.currentAlphaCoef - 0.15
      
    }
    
  }
  
  private func drawPath(isBackward: Bool) -> UIBezierPath {
    let path = UIBezierPath()
    
    guard let rect = self.seekView?.bounds else { return  UIBezierPath() }
    
     isBackward ? path.move(to: .zero) : path.move(to: CGPoint(x: 20, y: 0))
     //left side
     isBackward ?
       path.addLine(to: CGPoint(x: 0, y: rect.height))
       : path.addQuadCurve(to: CGPoint(x: 20, y: rect.height), controlPoint: CGPoint(x: -20, y: rect.height / 2))
     //bottom side
     isBackward ? path.addLine(to: CGPoint(x: rect.width - 20, y: rect.height))
       : path.addLine(to: CGPoint(x: rect.width, y: rect.height))
     //right side
     isBackward ? path.addQuadCurve(to: CGPoint(x: rect.width - 20, y: 0), controlPoint: CGPoint(x: rect.width + 20, y: rect.height / 2))
        : path.addLine(to: CGPoint(x: rect.width, y: 0))
     //top side
     isBackward ? path.move(to: .zero) : path.move(to: CGPoint(x: 20, y: 0))
     path.addLine(to: .zero)
     //close
     path.close()
    return path
  }
}