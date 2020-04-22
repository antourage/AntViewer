//
//  StreamViewCell.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/4/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit

public class StreamCell: UICollectionViewCell {

  @IBOutlet private var liveLabel: UILabel!
  @IBOutlet private var chatNameLabel: UILabel!
  @IBOutlet private var chatTextLabel: UILabel!
  @IBOutlet private var messageStackView: UIStackView!
  @IBOutlet private var watchedTimeLinePaddingView: UIView!
  @IBOutlet private var watchedTimeLineViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet private var circleImageView: UIImageView!
  @IBOutlet private var timeLabel: UILabel!
  @IBOutlet private var timeImageView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var subtitleLabel: UILabel!
  @IBOutlet var viewersCountLabel: UILabel!
  @IBOutlet var contentImageView: AVPlayerView!
  @IBOutlet var replayView: UIView!
  @IBOutlet var chatView: UIImageView!
  @IBOutlet var pollView: UIImageView!
  @IBOutlet var shareButton: UIButton!
  @IBOutlet var buttonsStackView: UIStackView!
  @IBOutlet var joinButton: UIButton!

  var message: (text: String, name: String, date: Date)? {
    didSet {
      if let message = self.message {
        chatTextLabel.text = message.text
        chatNameLabel.text = "\(message.name) • most recent"
        messageStackView.isHidden = false
      } else {
        messageStackView.isHidden = true
      }
    }
  }

  var isNew = false {
    didSet {
      liveLabel.isHidden = !isNew
      watchedTimeLinePaddingView.isHidden = isNew
      if isNew {
        liveLabel.text = "NEW"
        liveLabel.backgroundColor = UIColor.color("a_button_blue")
      }
    }
  }

  var isLive = true {
    didSet {
      liveLabel.isHidden = !isLive
      watchedTimeLinePaddingView.isHidden = isLive
      if isLive {
        liveLabel.text = "LIVE"
        liveLabel.backgroundColor = UIColor.color("a_pink")
      }
    }
  }

  var duration = 0 {
    didSet {
      if watchedTime > 0 {
        let watched = watchedTime.durationString
        timeLabel.text = "\(watched) / \(duration.durationString)"
      } else {
        timeLabel.text = "\(duration.durationString)"
      }
    }
  }

  var watchedTime = 0
    {
      didSet {
        watchedTimeLinePaddingView.isHidden = watchedTime <= 0
        guard watchedTime > 0, duration > 0 else {
          return
        }
        watchedTimeLineViewWidthConstraint.constant = (CGFloat(watchedTime) / CGFloat(duration)) * bounds.width
      }
    }

  lazy var userImageView: CacheImageView = {
    let imageView = CacheImageView()
    circleImageView.addSubview(imageView)
    imageView.layer.masksToBounds = true
    return imageView
  }()

  var shareAction: ((UICollectionViewCell) -> Void)?
  var joinAction: ((UICollectionViewCell) -> Void)?

  public override func layoutSubviews() {
    super.layoutSubviews()
    let width = circleImageView.bounds.width * 0.8
    userImageView.frame.size = CGSize(width: width, height: width)
    userImageView.layer.cornerRadius = width / 2
    userImageView.center = circleImageView.center
  }

  @IBAction private func shareButtonPressed(_ sender: UIButton) {
    shareAction?(self)
  }

  @IBAction private func joinButtonPressed(_ sender: UIButton) {
    joinAction?(self)
  }
  
}