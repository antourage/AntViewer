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

  lazy var progressView: UIView = {
    let progressView = UIView()
    cardView.insertSubview(progressView, at: 0)
    progressView.translatesAutoresizingMaskIntoConstraints = false
    progressView.leftAnchor.constraint(equalTo: cardView.leftAnchor).isActive = true
    progressView.topAnchor.constraint(equalTo: cardView.topAnchor).isActive = true
    progressView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor).isActive = true
    return progressView
  }()

  private var progressViewWidthConstrant: NSLayoutConstraint?

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
      progressView.backgroundColor = color.withAlphaComponent(0.33)
      cardView.layer.borderColor = color.cgColor
    }
  }

  var percentage: Int = 0 {
    didSet {
      guard isStatistic else { return }
      percentageLabel.text = String(format: "%d%%", percentage)
      progressViewWidthConstrant?.isActive = false
      progressViewWidthConstrant = nil
      progressViewWidthConstrant = progressView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: CGFloat(percentage)/100)
      progressViewWidthConstrant?.isActive = true
      cardView.layoutSubviews()
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    cardView.layer.borderColor = UIColor.pink.cgColor
  }
}
