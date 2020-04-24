//
//  EditProfileViewController.swift
//  AntViewer
//
//  Created by Maryan Luchko on 05.11.2019.
//

import UIKit
import AntViewerExt

protocol EditProfileControllerDelegate: class {
  func editProfileCloseButtonPressed(withChanges: Bool)
  func editProfileLoaded()
}

class EditProfileViewController: UIViewController {
  
  weak var delegate: EditProfileControllerDelegate?
  
  @IBOutlet weak var displayNameTextField: UITextField! {
    didSet {
      displayNameTextField.delegate = self
      displayNameTextField.attributedPlaceholder = NSAttributedString(string: "Type your display name", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
      displayNameTextField.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
      let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 20, height: displayNameTextField.bounds.height)))
      displayNameTextField.leftView = view
      displayNameTextField.leftViewMode = .always
      displayNameTextField.rightView = view
      displayNameTextField.rightViewMode = .always
    }
  }
  @IBOutlet weak var confirmButton: UIButton!

  var isConfirmButtonEnable = false {
      didSet {
        confirmButton.backgroundColor = isConfirmButtonEnable ? .designerGreen : confirmButtonDisabledColor
        confirmButton.isEnabled = isConfirmButtonEnable
      }
    }
    
  public var currentDisplayName: String = "" {
      didSet {
        displayNameTextField.placeholder = currentDisplayName.isEmpty ? "Type your display name" : currentDisplayName
      }
    }
  private let confirmButtonDisabledColor = UIColor(red: 204/255, green: 238/255, blue: 221/255, alpha: 1)

  private let maxCharactersCount = 50
  
  var isFirstTime = true

  override func viewDidLoad() {
      super.viewDidLoad()
      sutupUI()
    }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let textFieldHeight: CGFloat = OrientationUtility.isPortrait ? 48 : 36
    confirmButton.layer.cornerRadius = textFieldHeight/2
    displayNameTextField.layer.cornerRadius = textFieldHeight/2
  }

  deinit {
    print("EDIT PROFILE CONTROLLER DEINITED")
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    guard isFirstTime else { return }
    isFirstTime = false
    coordinator.animate(alongsideTransition: { (context) in
      self.displayNameTextField.endEditing(true)
    }) { (context) in
      self.displayNameTextField.becomeFirstResponder()
    }
  }

  @IBAction func cancelButtonPressed(_ sender: UIButton) {
    delegate?.editProfileCloseButtonPressed(withChanges: false)
  }

  @IBAction func confirmButtonPressed(_ sender: UIButton) {
     let text = displayNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true ? nil : displayNameTextField.text
       if let text = text {
        AntViewerManager.shared.change(displayName: text) { [weak self] (result) in
          guard let `self` = self else { return }
          switch result {
          case .success:
           self.currentDisplayName = User.current?.displayName ?? ""
            break
          case .failure:
            break
          }
          self.delegate?.editProfileCloseButtonPressed(withChanges: true)
        }
     }
  }

  func sutupUI() {
   currentDisplayName = User.current?.displayName ?? ""
   displayNameTextField.becomeFirstResponder()
   delegate?.editProfileLoaded()
   isConfirmButtonEnable = false
  }
}

extension EditProfileViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let currentText = textField.text ?? ""
    guard let stringRange = Range(range, in: currentText) else { return false }
    let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
    isConfirmButtonEnable = true
    
    guard !updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      isConfirmButtonEnable = false
      return true
    }
    if updatedText.count > maxCharactersCount + 1 {
        textField.text = String(updatedText.prefix(maxCharactersCount))
        return false
    }
    return updatedText.count <= maxCharactersCount
  }
}
