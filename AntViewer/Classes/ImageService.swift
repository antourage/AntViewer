//
//  ImageService.swift
//  AntViewer_ios
//
//  Created by Mykola Vaniurskyi on 22.10.2019.
//

import Foundation

extension UIImage: NSDiscardableContent {
  public func beginContentAccess() -> Bool { true }
  public func endContentAccess() {}
  public func discardContentIfPossible() {}
  public func isContentDiscarded() -> Bool { false }
}

class ImageService {
  
  static let cache: NSCache<NSString, UIImage> = {
    let newCache = NSCache<NSString, UIImage>()
    newCache.evictsObjectsWithDiscardedContent = true
    newCache.countLimit = 150
    return newCache
  }()
  
  static func downloadImage(withURL url:URL, completion: @escaping (_ image:UIImage?)->()) {
    let dataTask = URLSession.shared.dataTask(with: url) { data, responseURL, error in
      var downloadedImage:UIImage?
      
      if let data = data {
        downloadedImage = UIImage(data: data)
      }
      
      if downloadedImage != nil {
        cache.setObject(downloadedImage!, forKey: url.absoluteString as NSString)
      }
      
      DispatchQueue.main.async {
        completion(downloadedImage)
      }
    }
    
    dataTask.resume()
  }
  @discardableResult
  static func getImage(withURL url:URL, completion: @escaping (_ image:UIImage?)->()) -> Bool {
    if let image = cache.object(forKey: url.absoluteString as NSString) {
      completion(image)
      return true
    } else {
      downloadImage(withURL: url, completion: completion)
      return false
    }
  }
}
