//
//  FooterView.swift
//  AntViewer
//
//  Created by Maryan Luchko on 13.11.2019.
//

import UIKit

public class FooterView: UICollectionReusableView {

  @IBOutlet private var spinnerView: UIImageView!
  @IBOutlet var jumpButton: LocalizedButton!
  lazy private var animator = Animator(view: spinnerView, type: .fastSpin)
  var jumpAction: (() -> Void)?

  var showButton = false {
    didSet {
      jumpButton.isHidden = !showButton
      spinnerView.isHidden = showButton
    }
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    spinnerView.layer.cornerRadius = spinnerView.bounds.width / 2
  }

  @IBAction private func jumpButtonPressed(_ sender: LocalizedButton) {
    jumpAction?()
  }

  func startAnimating() {
    animator.animate(repeatCount: .infinity)
  }

  func stopAnimating() {
    animator.stop(immediately: true)
  }

}
