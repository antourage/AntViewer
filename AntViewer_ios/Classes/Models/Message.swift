//
//  Message.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/7/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import Foundation
import Firebase

public struct Message {
  
  public var key: String
  public let timestamp: Int
  let userID: String
  public let nickname: String
  public let text: String
  public let avatarUrl: String?
  
  public init(userID: String, timestamp: Int = Int(Date().timeIntervalSince1970), nickname: String, text: String , key: String = "", avatarUrl: String? = nil) {
    self.key = key
    self.timestamp = timestamp
    self.userID = userID
    self.nickname = nickname
    self.text = text
    self.avatarUrl = avatarUrl
  }
  
  public init?(snapshot: DocumentSnapshot) {
    guard
      let value = snapshot.data(),
      let userID = value["userID"] as? String,
      let nickname = value["nickname"] as? String,
      let text = value["text"] as? String,
      let avatarUrl = value["avatarUrl"] as? String?,
      let type = value["type"] as? Int,
      type == 1 else {
        return nil
    }
    
    self.key = snapshot.documentID
    self.userID = userID
    self.nickname = nickname
    self.text = text
    self.avatarUrl = avatarUrl
    self.timestamp = Int((value["timestamp"] as? Timestamp)?.dateValue().timeIntervalSince1970 ?? Date().timeIntervalSince1970)
  }
  
  func toAnyObject() -> [String: Any] {
    return [
      "avatarUrl": avatarUrl ?? "",
      "type": 1,
      "timestamp": FieldValue.serverTimestamp(),
      "userID": userID,
      "nickname": nickname,
      "text": text
    ]
  }
  
}
