//
//  UIView+Badge.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 29.03.2020.
//

import UIKit

extension UIView {

  /*
   * Assign badge with text,insets, and appearance.
   */
  public func badge(
    text badgeText: String?,
    badgeEdgeInsets: UIEdgeInsets? = nil,
    appearance: BadgeAppearance = BadgeAppearance()) {

    //Create badge label
    var badgeLabel: BadgeLabel!

    var doesBadgeExist = false

    //Find badge in subviews if exists
    for view in self.subviews {
      if view.tag == 1 && view is BadgeLabel {
        badgeLabel = (view as! BadgeLabel)
      }
    }

    //If assigned text is nil (request to remove badge) and badge label is not nil:
    if badgeText == nil && badgeLabel != nil {

      if appearance.animate {
        UIView.animate(withDuration: appearance.duration, animations: {
          badgeLabel.alpha = 0.0
          badgeLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        }, completion: { (_) in

          badgeLabel.removeFromSuperview()
        })
      } else {
        badgeLabel.removeFromSuperview()
      }
      return
    } else if badgeText == nil && badgeLabel == nil {
      return
    }

    //Badge label is nil (There was no previous badge)
    if (badgeLabel == nil) {
      badgeLabel = BadgeLabel()
      badgeLabel.tag = 1
    } else {
      doesBadgeExist = true
    }

    badgeLabel.textAlignment = appearance.textAlignment
    badgeLabel.textColor = appearance.textColor

    if doesBadgeExist {
      badgeLabel.removeFromSuperview()
    }

    if let size = appearance.size {
      badgeLabel.frame.size = size
    } else {
      let previousText = badgeLabel.text
      badgeLabel.text = badgeText
      badgeLabel.sizeToFit()
      badgeLabel.text = previousText
      let badgeSize = badgeLabel.frame.size
      let height = max(18, Double(badgeSize.height) + 5.0)
      let width = max(height, Double(badgeSize.width) + 10.0)
      badgeLabel.frame.size = CGSize(width: width, height: height)
    }
    let width = badgeLabel.frame.size.width
    let height = badgeLabel.frame.size.height

    //add to subview
    badgeLabel.layer.zPosition = 9999
    self.addSubview(badgeLabel)

    //The distance from the center of the view (vertically)
    let centerY = appearance.distanceFromCenterY == 0 ? -(bounds.size.height / 2) : appearance.distanceFromCenterY

    //The distance from the center of the view (horizontally)
    let centerX = appearance.distanceFromCenterX == 0 ? (bounds.size.width / 2) : appearance.distanceFromCenterX

    //disable auto resizing mask
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false

    //add height constraint
    if let badgeLabel = badgeLabel {
      self.addConstraint(NSLayoutConstraint(item: badgeLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(height)))

      //add width constraint
      self.addConstraint(NSLayoutConstraint(item: badgeLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(width)))

      //add vertical constraint
      self.addConstraint(NSLayoutConstraint(item: badgeLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: centerX))

      //add horizontal constraint
      self.addConstraint(NSLayoutConstraint(item: badgeLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: centerY))
    }

    badgeLabel.layer.borderColor = appearance.borderColor.cgColor
    badgeLabel.layer.borderWidth = appearance.borderWidth

    //corner radius
    badgeLabel.layer.cornerRadius = badgeLabel.frame.size.height / 2

    //setup shadow
    if appearance.allowShadow {
      badgeLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
      badgeLabel.layer.shadowRadius = 1
      badgeLabel.layer.shadowOpacity = 0.5
      badgeLabel.layer.shadowColor = UIColor.black.cgColor
    }

    func showBadge() {
      badgeLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
      badgeLabel.text = badgeText
      badgeLabel.font = appearance.font
      badgeLabel.layer.backgroundColor = appearance.backgroundColor.cgColor
      badgeLabel.alpha = 1
      UIView.animate(withDuration: appearance.duration,
                     animations: {
                      badgeLabel.transform = .identity
      },
                     completion: nil)
    }

    if appearance.animate {
      if doesBadgeExist {
        badgeLabel.fadeOut { value in
          showBadge()
        }
      } else {
        showBadge()
      }
    }
  }

}

extension UIBarButtonItem {

  /*
   * Assign badge with only text.
   */
  @objc public func badge(text: String?) {
    badge(text: text, appearance: BadgeAppearance())
  }

  public func badge(text badgeText: String?, appearance: BadgeAppearance = BadgeAppearance()) {
    if let view = badgeViewHolder {
      getView(in: view).badge(text: badgeText, appearance: appearance)
    } else {
      NSLog("Attempted setting badge with value '\(badgeText ?? "nil")' on a nil UIBarButtonItem view.")
    }
  }

  private var badgeViewHolder: UIView? {
    return value(forKey: "view") as? UIView
  }

  private func getView(in holder: UIView)->UIView{
    for sub in holder.subviews {
      if "\(type(of: sub))" == "_UIModernBarButton" {
        return sub
      }
    }
    return holder
  }


}

/*
 * BadgeLabel - This class is made to avoid confusion with other subviews that might be of type UILabel.
 */
@objc class BadgeLabel: UILabel {}

/*
 * BadgeAppearance - This struct is used to design the badge.
 */
public struct BadgeAppearance {
  public var font: UIFont = .systemFont(ofSize: 12)
  public var textAlignment: NSTextAlignment = .center
  public var borderColor: UIColor = .clear
  public var borderWidth: CGFloat = 0
  public var allowShadow: Bool = false
  public var backgroundColor: UIColor = .red
  public var textColor: UIColor = .white
  public var animate: Bool = true
  public var duration: TimeInterval = 0.3
  public var distanceFromCenterY: CGFloat = 0
  public var distanceFromCenterX: CGFloat = 0
  public var size: CGSize?

  public init() {}

}
