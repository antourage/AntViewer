//
//  UIViewController+Reachability.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 29.04.2020.
//

import UIKit
import AntViewerExt

class BottomMessage {

  private weak var presenter: UIViewController?
  private let debouncer = Debouncer(delay: 0)
  private var view: BottomView?
  private var topConstarint: NSLayoutConstraint?
  private var height: CGFloat = 20
  var onMessageAppear: ((_ height: CGFloat) -> Void)?
  var onMessageDisappear: ((_ height: CGFloat) -> Void)?

  init(presentingController: UIViewController){
    self.presenter = presentingController
  }

  private func createView() -> BottomView? {
    guard let presenterView = presenter?.view else { return nil }
    let messageView = BottomView()
    presenterView.addSubview(messageView)
    messageView.translatesAutoresizingMaskIntoConstraints = false
    height = 20 + (presenter?.view.safeAreaInsets.bottom ?? 0) * 0.7
    NSLayoutConstraint.activate([
      messageView.leadingAnchor.constraint(equalTo: presenterView.leadingAnchor),
      messageView.trailingAnchor.constraint(equalTo: presenterView.trailingAnchor),
      messageView.heightAnchor.constraint(equalToConstant: height)
    ])
    topConstarint = messageView.topAnchor.constraint(equalTo: presenterView.bottomAnchor)
    topConstarint?.isActive = true
    presenterView.layoutIfNeeded()
    return messageView
  }

  private func showAnimation() {
    guard topConstarint?.constant != -height else {
      return
    }
    onMessageAppear?(height)
    topConstarint?.constant = -height
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
      self.presenter?.view.layoutIfNeeded()
    }, completion: nil)
  }

  private func hideAnimation(){
    let view = self.view
    self.view = nil
    onMessageDisappear?(height)
    topConstarint?.constant = 0
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
      self.presenter?.view.layoutIfNeeded()
    }) { success in
      view?.removeFromSuperview()
    }
  }

  func hideMessage() {
    hideAnimation()
  }

  func showMessage(title: String, duration: Double = .infinity, backgroundColor: UIColor = .gray) {
    debouncer.call {}
    if view == nil {
      view = createView()
    }
    view?.titleLabel.text = title
    view?.titleLabel.sizeToFit()
    view?.layoutIfNeeded()
    view?.backgroundColor = backgroundColor
    showAnimation()
    guard duration != .infinity else {
      return
    }

    debouncer.call(delay: duration) { [weak self] in
      self?.hideMessage()
    }
  }

}

private class BottomView: UIView {
  lazy var titleLabel: UILabel = {
    let title = UILabel()
    title.textAlignment = .center
    title.textColor = .white
    title.font = UIFont.systemFont(ofSize: 9, weight: .bold)
    self.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
      title.centerXAnchor.constraint(equalTo: self.centerXAnchor)
    ])
    return title
  }()
}

