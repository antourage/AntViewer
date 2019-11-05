//
//  EditProfileViewController.swift
//  AntViewer
//
//  Created by Maryan Luchko on 05.11.2019.
//

import UIKit
import AntViewerExt

class EditProfileViewController: UIViewController {
  
  var editProfileView: EditProfileView?
  
  var editProfileViewBottomConstraint: NSLayoutConstraint!
  var leadingConstraint: NSLayoutConstraint!
  var trailingConstraint: NSLayoutConstraint!
  
  weak var playerController: PlayerController?
  
  var heightOfMessageTextView: CGFloat? {
    OrientationUtility.isPortrait ? playerController?.portraitBottomContainerView.bounds.height : playerController?.landscapeBottomContainerView.bounds.height
  }

  var margins: CGFloat {
    get {
      let landscapeMargin: CGFloat = self.view.safeAreaInsets.left > 0 || playerController!.view.safeAreaInsets.right > 0 ? 30 : 0
      return OrientationUtility.isPortrait ? 20 : landscapeMargin
    }
  }
    override func viewDidLoad() {
        super.viewDidLoad()
      sutupUI()
      
      var token: NSObjectProtocol?
      token = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] (notification) in
        guard let `self` = self else {
          NotificationCenter.default.removeObserver(token!)
          return
        }

        self.leadingConstraint.constant = self.margins
        self.trailingConstraint.constant = self.margins
        self.view.layoutIfNeeded()
      }
      
        // Do any additional setup after loading the view.
    }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }
  
  @IBAction func handleTapOnFreeArea(_ sender: UITapGestureRecognizer) {
    if !(editProfileView?.frame.contains(sender.location(in: self.view)) ?? false) {
      dismiss(animated: false, completion: nil)
    }
  }
  
  func sutupUI() {
     editProfileView = EditProfileView()
     editProfileView?.currentDisplayName = User.current?.displayName ?? ""
     editProfileView?.displayNameTextField.becomeFirstResponder()
     self.view.addSubview(editProfileView!)
    
    playerController?.portraitEditProfileButton.tintColor = .white
    playerController?.landscapeEditProfileButton.tintColor = .white
    
    editProfileSetConstraints()

     if let imageURL = User.current?.imageUrl {
       editProfileView?.userImage.load(url: URL(string: imageURL), placeholder: nil)
     }

     editProfileView?.confirmButtonPressed = { [weak self] (text, image) in
      let group = DispatchGroup()
      if let text = text {
        group.enter()
       AntViewerManager.shared.change(displayName: text) { [weak self] (result) in
         guard let `self` = self else { return }
         switch result {
         case .success:
          self.editProfileView?.currentDisplayName = User.current?.displayName ?? ""
           break
         case .failure:
           break
         }
         group.leave()
       }
      }

       if let image = image, let data = image.jpegData(compressionQuality: 0.5) {
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
        self?.editProfileView?.removeFromSuperview()
          self?.dismiss(animated: false, completion: nil)
       }
     }

     editProfileView?.cancelButtonPressed = { [weak self] in
      self?.dismiss(animated: false, completion: nil)
     }

      editProfileView?.changeProfileImage = { [weak self] in
          self?.showImagePickAlert()
     }
  }
  
  deinit {
    playerController?.portraitEditProfileButton.tintColor = .darkGray
    playerController?.landscapeEditProfileButton.tintColor = .darkGray
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
      self.editProfileView?.displayNameTextField.becomeFirstResponder()
    }
    alertController.addAction(takePhotoAction)
    alertController.addAction(chooseFromLibraryAction)
    alertController.addAction(closeAction)
    present(alertController, animated: true, completion: nil)
  }
  
  private func editProfileSetConstraints() {
    leadingConstraint = NSLayoutConstraint(item: editProfileView as Any,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: .leading,
                                          multiplier: 1,
                                          constant: margins)
    leadingConstraint.isActive = true
    trailingConstraint = NSLayoutConstraint(item: view as Any,
                                           attribute: .trailing,
                                           relatedBy: .equal,
                                           toItem: editProfileView as Any,
                                           attribute: .trailing,
                                           multiplier: 1,
                                           constant: margins)
    trailingConstraint.isActive = true
    editProfileViewBottomConstraint = NSLayoutConstraint(item: view as Any,
                                         attribute: .bottom,
                                         relatedBy: .equal,
                                         toItem: editProfileView as Any,
                                         attribute: .bottom,
                                         multiplier: 1,
                                         constant: 0)
    editProfileViewBottomConstraint.isActive = true
    self.view.addConstraints([leadingConstraint, trailingConstraint, editProfileViewBottomConstraint])
  }
  
  @objc
    fileprivate func keyboardWillShow(notification: NSNotification) {
      if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
        let userInfo = notification.userInfo!
        let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let rawAnimationCurve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value << 16
        let animationCurve = UIView.AnimationOptions.init(rawValue: UInt(rawAnimationCurve))
        
        editProfileViewBottomConstraint.constant = keyboardSize.height + (heightOfMessageTextView ?? 0)
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState, animationCurve], animations: {
          self.view.layoutIfNeeded()
        }, completion: nil)
      }
    }
    
    @objc
    fileprivate func keyboardWillHide(notification: NSNotification) {
      if let _ = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        editProfileViewBottomConstraint.constant = heightOfMessageTextView ?? 0
        UIView.animate(withDuration: 0.3) {
          self.view.layoutIfNeeded()
        }
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
    self.editProfileView?.selectedImage = image
    picker.dismiss(animated: true, completion: nil)
    self.editProfileView?.displayNameTextField.becomeFirstResponder()
  }
}
