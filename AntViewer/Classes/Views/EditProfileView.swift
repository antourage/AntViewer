//
//  EditProfileView.swift
//  AntViewer_ios
//
//  Created by Maryan Luchko on 9/13/19.
//

import UIKit

class EditProfileView: UIView {

  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var displayNameTextField: UITextField! {
    didSet {
      displayNameTextField.delegate = self
      displayNameTextField.attributedPlaceholder = NSAttributedString(string: "Type your display name", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
    }
  }
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var infoLabel: UILabel!
  @IBOutlet weak var userImage: CacheImageView! 
  
  var isConfirmButtonEnable = false {
    didSet {
      confirmButton.backgroundColor = isConfirmButtonEnable ? confirmButtonEnabledColor : confirmButtonDisabledColor
        confirmButton.isEnabled = isConfirmButtonEnable
    }
  }
  
  public var currentDisplayName: String = "" {
    didSet {

      displayNameTextField.placeholder = currentDisplayName.isEmpty ? "Type your display name" : currentDisplayName
    }
  }
 private let confirmButtonEnabledColor = UIColor(red: 5/255, green: 168/255, blue: 84/255, alpha: 1)
 private let confirmButtonDisabledColor = UIColor(red: 204/255, green: 238/255, blue: 221/255, alpha: 1)
  
 private let maxCharactersCount = 50
  
  var confirmButtonPressed: ((String, UIImage?) -> ())?
  var cancelButtonPressed: (() -> ())?
  var changeProfileImage: (() -> ())?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    fatalError("init(coder:) has not been implemented")
  }
  
  init() {
    let _width = (UIScreen.main.bounds.width * 0.9) < 360 ? UIScreen.main.bounds.width * 0.9 : 360
    let _height: CGFloat = 150
    super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: _width, height: _height)))
    commonInit()
  }
  
  enum ViewPosition {
    case top, bottom
  }
  
  private func commonInit() {
    Bundle(for: type(of: self)).loadNibNamed("EditProfileView", owner: self, options: nil)
    addSubview(contentView)
    contentView.frame = bounds
    isConfirmButtonEnable = false
  }
  
  override func removeFromSuperview() {
    super.removeFromSuperview()
    displayNameTextField.text = nil
  }
  
  @IBAction func cancelButtonPressed(_ sender: UIButton) {
    cancelButtonPressed?()
  }
  
  @IBAction func confirmButtonPressed(_ sender: UIButton) {
    let text = displayNameTextField.text!
    confirmButtonPressed?(text, nil)
  }
  
  @IBAction func onUserAvatarTapped(_ sender: UITapGestureRecognizer) {
    self.displayNameTextField.resignFirstResponder()
    changeProfileImage?()
  }
}

extension EditProfileView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }
  
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