//
//  PlayerController+Polls.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 23.11.2020.
//

import Foundation

extension PlayerController {
  func collapsePollBanner(animated: Bool = true) {
    pollBannerPortraitLeading.isActive = false
    pollBannerAspectRatio.isActive = true
    UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
      self.view.layoutIfNeeded()
    })
  }

  func expandPollBanner() {
    pollBannerAspectRatio.isActive = false
    if OrientationUtility.currentOrientatin.isPortrait {
      pollBannerPortraitLeading.isActive = true
    }
    UIView.animate(withDuration: 0.3, animations: {
      self.view.layoutIfNeeded()
    })
    guard isFirstTimeBannerShown else { return }
    isFirstTimeBannerShown = false
    pollBannerDebouncer.call { [weak self] in
      self?.shouldShowExpandedBanner = false
      self?.collapsePollBanner()
    }
  }
  
  @IBAction func openPollBannerPressed(_ sender: Any) {
    guard editProfileContainerView.isHidden else { return }
    dismissEditProfileView()
    shouldEnableMessageTextFields(false)
    view.endEditing(true)
    pollController = PollController()
    pollController?.poll = activePoll
    guard let pollController = pollController else {return}
    addChild(pollController)
    pollContainerView.addSubview(pollController.view)
    pollController.view.frame = pollContainerView.bounds
    pollController.didMove(toParent: self)
    pollController.delegate = self
    pollContainerView.isHidden = false
    updateChatVisibility()
    pollBannerIcon.hideBadge()
    collapsePollBanner(animated: false)
    shouldShowPollBadge = true
    shouldShowExpandedBanner = false
    updateBottomContainerVisibility()
  }
  
}

extension PlayerController: PollControllerDelegate {
  
  func pollControllerCloseButtonPressed() {
    pollController?.willMove(toParent: nil)
    pollController?.view.removeFromSuperview()
    pollController?.removeFromParent()
    pollController = nil
    pollContainerView.isHidden = true
    updateChatVisibility()
    pollAnswersFromLastView = activePoll?.answersCount.reduce(0,+) ?? 0
    updateBottomContainerVisibility()
    shouldEnableMessageTextFields(true)
  }
}
