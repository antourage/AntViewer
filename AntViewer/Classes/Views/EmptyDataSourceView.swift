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
  
  @IBOutlet private var fakeCellsArray: [UIView]!
  private var stateArray = [true, true, true, false]
  private let startAnimationAlpha: [CGFloat] = [0.07, 0.14, 0.21, 0.28]
  public var isLoading = false {
    didSet {
      if isLoading {
        self.fakeCellsArray.enumerated().forEach { [weak self] element in
          element.element.backgroundColor = UIColor.white.withAlphaComponent(self?.startAnimationAlpha[element.offset] ?? 0)
        }
        startTimer()
      } else {
        stopTimer()
        fakeCellsArray.forEach { $0.backgroundColor = UIColor.white.withAlphaComponent(0.1)}
      }
    }
  }
  
  public var minShowTime: Double = 0.7
  private var showTime: Double = 0
  
  private let maxAlpha: CGFloat = 0.28
  private let minAlpha: CGFloat = 0.07
  
  private var timer: Timer?
  
  
  private func updateBackgroungColor(_ enumeratedView: (index:Int, view:UIView)) {
    var currnetState = self.stateArray[enumeratedView.index]
    var currentAlpha: CGFloat = 0
    enumeratedView.view.backgroundColor?.getWhite(nil, alpha: &currentAlpha)
    let numberOfPlaces = 3.0
    let multiplier = CGFloat(pow(10.0, numberOfPlaces))
    currentAlpha = (currentAlpha * multiplier).rounded(.toNearestOrAwayFromZero) / multiplier
    if currentAlpha <= minAlpha || currentAlpha >= maxAlpha {
      currnetState = currentAlpha == minAlpha ? true : false
    }
    self.stateArray[enumeratedView.index] = currnetState
    currentAlpha += currnetState ? 0.035 : -0.035
    enumeratedView.view.backgroundColor = UIColor.white.withAlphaComponent(currentAlpha)
  }
  
  private func startTimer() {
    self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
      guard let `self` = self else { return }
      self.fakeCellsArray.enumerated().forEach({ self.updateBackgroungColor($0) })
    })
  }
  
  private func stopTimer() {
    self.timer?.invalidate()
    self.timer = nil
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
