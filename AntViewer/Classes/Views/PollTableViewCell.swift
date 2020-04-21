//
//  PollTableViewCell.swift
//  AntViewer
//
//  Created by Maryan Luchko on 21.04.2020.
//

import UIKit

class PollTableViewCell: UITableViewCell {
  @IBOutlet weak var cardView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var percentageLabel: UILabel!

  lazy var progressLayer: CALayer = {
    let layer = CALayer()
    cardView.layer.insertSublayer(layer, at: 0)
    return layer
  }()

  var isStatistic = false {
    didSet {
      percentageLabel.isHidden = !isStatistic
      titleLabel.textAlignment = isStatistic ? .left : .center
    }
  }

  var isUserChoise = false {
    didSet {
      guard isStatistic else { return }
      let color = isUserChoise ?
      UIColor.pink :
      UIColor.cellGray
      percentageLabel.textColor = color
      progressLayer.backgroundColor = color.withAlphaComponent(0.33).cgColor
      cardView.layer.borderColor = color.cgColor
    }
  }

  var percentage: Int = 0 {
    didSet {
      percentageLabel.text = String(format: "%d", percentage)
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    cardView.layer.borderColor = UIColor.pink.cgColor
  }

  override func setNeedsDisplay() {
    super.setNeedsDisplay()
    guard isStatistic else { return }
    progressLayer.frame = CGRect(origin: .zero, size: CGSize(width: cardView.bounds.width*(CGFloat(percentage)/100), height: cardView.bounds.height))
  }
}
