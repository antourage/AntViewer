//
//  PollManager.swift
//  AntViewerExt
//
//  Created by Maryan Luchko on 8/29/19.
//  Copyright © 2019 Antourage. All rights reserved.
//


import Foundation
import Firebase
import ViewerExtension

final class FirePollManager: PollManager {

  private var streamId: Int
  private var path: String
  private  var pollListener: ListenerRegistration?
  
  public init(streamId: Int, path: String) {
    self.streamId = streamId
    self.path = path
  }
  
  func observePolls(deviceID: String, completion: @escaping((Poll?) -> ())) {

    let app = FirebaseApp.app(name: "AntViewerFirebase")!
    let ref = Firestore.firestore(app: app).collection(path)
    
    pollListener = ref.whereField("isActive", isEqualTo: true).addSnapshotListener( { (querySnapshot, error) in
      guard let document = querySnapshot?.documents.first else {
        print("Error fetching documents or empty")
        completion(nil)
        return
      }
      if let newPoll = FirePoll(snapshot: document, deviceID: deviceID) {
        completion(newPoll)
      }
    })
  }
  
  func removeFirebaseObserver() {
    pollListener?.remove()
    pollListener = nil
  }
}

