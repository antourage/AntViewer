//
//  StreamViewCell.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/4/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AntViewerExt

public class StreamCell: UICollectionViewCell {

  @IBOutlet private var liveLabel: UILabel!
  @IBOutlet private var chatNameLabel: UILabel!
  @IBOutlet private var chatTextLabel: UILabel!
  @IBOutlet private var messageStackView: UIStackView!
  @IBOutlet private var watchedTimeLinePaddingView: UIView!
  @IBOutlet private var watchedTimeLineViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet private var circleImageView: UIImageView!
  @IBOutlet private var timeLabel: UILabel!
  @IBOutlet var timeImageView: UIImageView! {
    didSet {
      let images = Array(0...24).compactMap {
        UIImage.image(String(format: "Autoplay%02d", $0))
      }
      timeImageView.animationImages = images
    }
  }
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var subtitleLabel: UILabel!
  @IBOutlet var viewersCountLabel: UILabel!
  @IBOutlet var contentImageView: AVPlayerView!
  @IBOutlet var replayView: UIView!
  @IBOutlet var chatView: UIImageView!
  @IBOutlet var pollView: UIImageView!
  @IBOutlet var shareButton: UIButton!
  @IBOutlet var buttonsStackView: UIStackView!
  @IBOutlet var joinButton: LocalizedButton!
  @IBOutlet private var timeLabelWidth: NSLayoutConstraint!

  var message: LatestComment? {
    didSet {
      if let message = self.message {
        let isCurrentUser = Int(message.userID) == User.current?.id
        let userName = isCurrentUser ? User.current?.displayName ?? message.nickname : message.nickname
        chatTextLabel.text = message.text
        chatNameLabel.text = "\(userName) • \(LocalizedStrings.mostRecent.localized)"
        messageStackView.isHidden = false
        chatView.isHidden = false
      } else {
        messageStackView.isHidden = true
      }
    }
  }

  var chatEnabled = false


  var isNew = false {
    didSet {
      liveLabel.isHidden = !isNew
      watchedTimeLinePaddingView.isHidden = isNew
      if isNew {
        liveLabel.text = LocalizedStrings.new.localized.uppercased()
        liveLabel.backgroundColor = UIColor.color("a_button_blue")
      }
    }
  }

  var isLive = false {
    didSet {
      liveLabel.isHidden = !isLive
      watchedTimeLinePaddingView.isHidden = isLive
      if isLive {
        liveLabel.text = LocalizedStrings.live.localized.uppercased()
        liveLabel.backgroundColor = UIColor.color("a_pink")
        chatView.isHidden = !chatEnabled
      }
    }
  }

  var duration = 0 {
    didSet {
      updateTime()
    }
  }

  var watchedTime: Int?
    {
      didSet {
        updateTime()
      }
    }

  lazy var userImageView: CacheImageView = {
    let imageView = CacheImageView()
    imageView.contentMode = .scaleAspectFill
    circleImageView.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.centerXAnchor.constraint(equalToSystemSpacingAfter: circleImageView.centerXAnchor, multiplier: 1).isActive = true
    imageView.centerYAnchor.constraint(equalToSystemSpacingBelow: circleImageView.centerYAnchor, multiplier: 1).isActive = true
    imageView.widthAnchor.constraint(equalTo: circleImageView.widthAnchor, multiplier: 0.8).isActive = true
    imageView.heightAnchor.constraint(equalTo: circleImageView.heightAnchor, multiplier: 0.8).isActive = true
    imageView.layer.masksToBounds = true
    return imageView
  }()

  var shareAction: ((UICollectionViewCell) -> Void)?
  var joinAction: ((UICollectionViewCell) -> Void)?

  public override func layoutSubviews() {
    super.layoutSubviews()
    userImageView.layer.cornerRadius = userImageView.bounds.height/2
  }

  private func configureTimeLabelWidth() {
    let label = UILabel()
    label.font = timeLabel.font
    label.text = timeLabel.text?.replacingOccurrences( of:"[0-9]", with: "8", options: .regularExpression)
    timeLabelWidth.constant = label.intrinsicContentSize.width
    layoutIfNeeded()
  }

  private func updateTime() {
    guard let watchedTime = watchedTime else {
      timeLabel.text = "\(duration.durationString())"
      configureTimeLabelWidth()
      watchedTimeLinePaddingView.isHidden = true
      return
    }
    if watchedTime > 0 {
      let remains = duration - watchedTime
      timeLabel.text = "\(remains.durationString())"
    } else {
      timeLabel.text = "\(duration.durationString())"
    }
    configureTimeLabelWidth()
    if isLive {
      watchedTimeLinePaddingView.isHidden = true
    } else {
      if watchedTimeLinePaddingView.isHidden {
        watchedTimeLinePaddingView.alpha = 0
        watchedTimeLinePaddingView.isHidden = false
        UIView.animate(withDuration: 0.2) {
          self.watchedTimeLinePaddingView.alpha = 1
        }
      }
    }
    let koef: CGFloat = duration != .zero ? (CGFloat(watchedTime) / CGFloat(duration)) : 0
    watchedTimeLineViewWidthConstraint.constant = koef * bounds.width
  }

  @IBAction private func shareButtonPressed(_ sender: UIButton) {
    shareAction?(self)
  }

  @IBAction private func joinButtonPressed(_ sender: UIButton) {
    joinAction?(self)
  }
  
}
