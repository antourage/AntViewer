//
//  CacheImageView.swift
//  AntViewer_ios
//
//  Created by Mykola Vaniurskyi on 22.10.2019.
//

import UIKit

class CacheImageView: UIImageView {
  
  private var imageUrlString: String?
  
  func load(url: URL?, placeholder: UIImage?) {
    guard let url = url else {return}
    imageUrlString = url.absoluteString
    if !ImageService.getImage(withURL: url, completion: { (newImage) in
      if self.imageUrlString == url.absoluteString {
        self.image = newImage ?? placeholder
      }
    }) {
      image = placeholder
    }
  }
}
