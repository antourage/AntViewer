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

public class PollManager {
  
  private var streamId: Int
  private  var pollListener: ListenerRegistration?
  
  public init(streamId: Int) {
    self.streamId = streamId
  }
  
  public func observePolls(completion: @escaping((Poll?) -> ())) {
    let app = FirebaseApp.app(name: "AntViewerFirebase")!
    let ref = Firestore.firestore(app: app).collection("antourage/\(Environment.current.rawValue)/streams/\(streamId)/polls")
    
    pollListener = ref.whereField("isActive", isEqualTo: true).addSnapshotListener( { (querySnapshot, error) in
      guard let document = querySnapshot?.documents.first else {
        print("Error fetching documents or empty")
        completion(nil)
        return
      }
      if let newPoll = Poll(snapshot: document) {
        completion(newPoll)
      }
    })
  }
  
  public func removeFirObserver() {
    pollListener?.remove()
    pollListener = nil
  }
}

