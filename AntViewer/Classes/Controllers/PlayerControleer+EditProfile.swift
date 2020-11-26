//
//  PlayerControleer+EditProfile.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 23.11.2020.
//

import Foundation

extension PlayerController {
  @IBAction func editProfileButtonPressed(_ sender: UIButton?) {
    if editProfileContainerView.isHidden {
      showEditProfileView()
    } else {
      dismissEditProfileView()
    }
  }
  
  func showEditProfileView() {
    guard pollContainerView.isHidden else { return }
    editProfileControllerIsLoading = true
    shouldEnableMessageTextFields(false)
    let editProfileController = EditProfileViewController(nibName: "EditProfileViewController", bundle: Bundle(for: type(of: self)))
    editProfileController.delegate = self
    addChild(editProfileController)
    editProfileContainerView.addSubview(editProfileController.view)
    editProfileController.didMove(toParent: self)
    editProfileController.view.translatesAutoresizingMaskIntoConstraints = false
    UIView.performWithoutAnimation {
      editProfileController.view.topAnchor.constraint(equalTo: self.editProfileContainerView.topAnchor).isActive = true
      editProfileController.view.leftAnchor.constraint(equalTo: self.editProfileContainerView.leftAnchor).isActive = true
      editProfileController.view.rightAnchor.constraint(equalTo: self.editProfileContainerView.rightAnchor).isActive = true
      editProfileController.view.bottomAnchor.constraint(equalTo: self.editProfileContainerView.bottomAnchor).isActive = true
    }

    let paddingView = UIView(frame: view.bounds)
    paddingView.backgroundColor = UIColor.gradientDark.withAlphaComponent(0.8)
    paddingView.tag = 1234
    paddingView.translatesAutoresizingMaskIntoConstraints = false
    view.insertSubview(paddingView, belowSubview: editProfileContainerView)
    paddingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    paddingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    paddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    paddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    editProfileContainerView.isHidden = false
  }
  
  func dismissEditProfileView() {
    shouldEnableMessageTextFields(true)
    view.subviews.first { $0.tag == 1234 }?.removeFromSuperview()
    editProfileContainerView.isHidden = true
    let editProfile = children.first(where: { $0 is EditProfileViewController})
    editProfile?.willMove(toParent: nil)
    editProfile?.view.removeFromSuperview()
    editProfile?.removeFromParent()
  }
}

extension PlayerController: EditProfileControllerDelegate {
  func editProfileLoaded() {
    editProfileControllerIsLoading = false
  }
  
  func editProfileCloseButtonPressed(withChanges: Bool) {
    if withChanges {
      chatController.reloadData()
    }
    dismissEditProfileView()
  }
}
