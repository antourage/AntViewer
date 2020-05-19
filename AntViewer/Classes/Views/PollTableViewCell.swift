//
//  PollTableViewCell.swift
//  AntViewer
//
//  Created by Maryan Luchko on 21.04.2020.
//

import UIKit

public class PollTableViewCell: UITableViewCell {
  @IBOutlet private var cardView: UIView!
  @IBOutlet public var titleLabel: UILabel!
  @IBOutlet private var percentageLabel: UILabel!
  @IBOutlet private var titleLabelTrailing: NSLayoutConstraint!

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

  public var isStatistic = false {
    didSet {
      titleLabel.textAlignment = isStatistic ? .left : .center
      percentageLabel.isHidden = !isStatistic
      titleLabelTrailing.isActive = !isStatistic
      animateChanges()
    }
  }

  public var isUserChoise = false {
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

  public var percentage: Int = 0 {
    didSet {
      guard isStatistic else { return }
      percentageLabel.text = String(format: "%d%%", percentage)
      progressViewWidthConstrant?.isActive = false
      progressViewWidthConstrant = nil
      progressViewWidthConstrant = progressView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: CGFloat(percentage)/100)
      progressViewWidthConstrant?.isActive = true
      animateChanges()
    }
  }

  private func animateChanges() {
    UIView.animate(withDuration: 0.3) {
      self.cardView.layoutSubviews()
    }
  }

  public override func awakeFromNib() {
    super.awakeFromNib()
    cardView.layer.borderColor = UIColor.pink.cgColor
  }
}
