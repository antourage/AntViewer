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
    }
  }
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var userImage: CacheImageView!
    
    var isConfirmButtonEnable = false {
      didSet {
        confirmButton.backgroundColor = isConfirmButtonEnable ? confirmButtonEnabledColor : confirmButtonDisabledColor
        confirmButton.isEnabled = isConfirmButtonEnable
      }
    }
    
    var selectedImage: UIImage? {
      didSet {
        isConfirmButtonEnable = true
        userImage.image = selectedImage
        if selectedImage == nil, displayNameTextField.text?.isEmpty ?? true {
          isConfirmButtonEnable = false
        }
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
  
    var isFirstTime = true
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
      delegate?.editProfileCloseButtonPressed(withChanges: false)
    }
    
    @IBAction func confirmButtonPressed(_ sender: UIButton) {
      let text = displayNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true ? nil : displayNameTextField.text
      let group = DispatchGroup()
            if let text = text {
              group.enter()
             AntViewerManager.shared.change(displayName: text) { [weak self] (result) in
               guard let `self` = self else { return }
               switch result {
               case .success:
                self.currentDisplayName = User.current?.displayName ?? ""
                 break
               case .failure:
                 break
               }
               group.leave()
             }
            }
      
      if let image = self.selectedImage, let data = image.jpegData(compressionQuality: 0.3) {
               group.enter()
               AntViewerManager.shared.uploadImage(data: data) {  (response) in
                 switch response {
                 case .success:
                   break
                 case .failure(let error):
                   print("Error uploading image: \(error.localizedDescription)")
                 }
                 group.leave()
               }
             }
      
           group.notify(queue: .main) { [weak self] in
            self?.delegate?.editProfileCloseButtonPressed(withChanges: true)
           }
      
    }
    
    @IBAction func onUserAvatarTapped(_ sender: UITapGestureRecognizer) {
      self.displayNameTextField.resignFirstResponder()
      showImagePickAlert()
    }
  
  
    override func viewDidLoad() {
        super.viewDidLoad()
      sutupUI()


    }
  
  func sutupUI() {
     currentDisplayName = User.current?.displayName ?? ""
     displayNameTextField.becomeFirstResponder()
     if let imageURL = User.current?.imageUrl {
      userImage.load(url: URL(string: imageURL), placeholder: UIImage.image("v1"))
     }

    delegate?.editProfileLoaded()
  }
//
  deinit {
    print("EDIT PROFILE CONTROLLER DEINITED")
  }
  
  func showImagePickAlert() {
    let alertController = UIAlertController()
    alertController.message = "Choose source of the image"
    let takePhotoAction = UIAlertAction(title: "From camera", style: UIAlertAction.Style.default) { _ in
      let imagePicker = UIImagePickerController()
      imagePicker.delegate = self
      imagePicker.sourceType = UIImagePickerController.SourceType.camera
      imagePicker.allowsEditing = true
      self.present(imagePicker, animated: true, completion: nil)
    }
    let chooseFromLibraryAction = UIAlertAction(title: "From gallery", style: UIAlertAction.Style.default) { _ in
      let imagePicker = UIImagePickerController()
      imagePicker.delegate = self
      imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
      imagePicker.allowsEditing = true
      self.present(imagePicker, animated: true, completion: nil)
    }
    let closeAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { _ in
      self.displayNameTextField.becomeFirstResponder()
    }
    alertController.addAction(takePhotoAction)
    alertController.addAction(chooseFromLibraryAction)
    alertController.addAction(closeAction)
    present(alertController, animated: true, completion: nil)
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

  
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

    guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
      picker.dismiss(animated: false, completion: nil)
      assert(false, "Failed to load edited image data")
      return
    }
    self.selectedImage = image
    picker.dismiss(animated: true, completion: nil)
    self.displayNameTextField.becomeFirstResponder()
  }
}

extension EditProfileViewController: UITextFieldDelegate {
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let currentText = textField.text ?? ""
    guard let stringRange = Range(range, in: currentText) else { return false }
    let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
    isConfirmButtonEnable = true
    
    guard !updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      if selectedImage == nil {
      isConfirmButtonEnable = false
      }
      return true
    }
    
    if updatedText.count > maxCharactersCount + 1 {
        textField.text = String(updatedText.prefix(maxCharactersCount))
        return false
    }
   
    
    return updatedText.count <= maxCharactersCount
  }
}
