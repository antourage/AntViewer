//
//  MessageFetcher.swift
//  AntViewer
//
//  Created by Maryan Luchko on 14.05.2020.
//

import Foundation
import Firebase
import ViewerExtension

final class MessageFetcher: FirebaseFetcher {

  var firebaseApp: FirebaseApp

  init() {
    self.firebaseApp = FirebaseApp.app(name: "AntViewerFirebase")!
  }

  func setLatestMessagesTo(VODs: [VOD], completion: @escaping(()->())) {
     let group = DispatchGroup()
     for video in VODs {
       group.enter()
       let vodFromCache = StorageManager.shared.loadVideoContent(content: video)
       if vodFromCache.latestCommentLoaded {
         video.latestMessage = vodFromCache.latestMessage
         group.leave()
       } else {
         getLatestMessageFor(video: video, completion: { infoDict in
          let latestComment = infoDict[video.id]
          video.latestMessage = latestComment
          StorageManager.shared.saveLatestComment(for: video, value: latestComment)
          group.leave()
         })
       }
     }
     group.notify(queue: .main) {
       completion()
     }
  }

  func setInfoTo(lives: [Live], completion: @escaping(()->())) {
    var liveInfo = Dictionary<Int, (LatestComment?, Bool, Bool)>()
    lives.forEach { liveInfo[$0.id] = (nil, false, false) }
    let group = DispatchGroup()

    for video in lives {
      group.enter()
      getLatestMessageFor(video: video, completion: { infoDict in
        video.latestMessage = infoDict[video.id]
        group.leave()
      })
      group.enter()
      checkPollStatus(live: video, completion: { infoDict in
        video.isPollOn = infoDict[video.id] ?? false
        group.leave()
      })
      group.enter()
      checkChatState(live: video) { (infoDict) in
        video.isChatOn = infoDict[video.id] ?? false
        group.leave()
      }
    }
    group.notify(queue: .main) {
      completion()
    }
  }

  private func getLatestMessageFor(video: VideoContent, completion: @escaping(([Int: LatestComment])->())) {
    let ref = Firestore.firestore(app: firebaseApp)
      .collection("antourage/\(Environment.current.rawValue)/streams")
      .document("\(video.id)")
      .collection("messages")
      .whereField("type", isEqualTo: 1)
      .order(by: "timestamp", descending: true)
      .limit(to: 1)

    ref.getDocuments { (snapshot, error) in
      if let json = snapshot?.documents.first?.data(),
        let nickname = json["nickname"] as? String,
        let text = json["text"] as? String {
        let userID = json["userID"] as? String ?? ""
        completion([video.id : LatestComment(userID: userID,nickname: nickname, text: text, timestamp: 0)])
      } else {
        completion([:])
      }
    }
  }

  private func checkPollStatus(live: VideoContent, completion: @escaping(([Int: Bool])->())) {
    let ref = Firestore.firestore(app: firebaseApp)
      .collection("antourage/\(Environment.current.rawValue)/streams/\(live.id)/polls")
      .whereField("isActive", isEqualTo: true)
    ref.getDocuments { (snapshot, _) in
      completion([live.id: !(snapshot?.documents.isEmpty ?? true)])
    }
  }

  private func checkChatState(live: VideoContent, completion: @escaping(([Int: Bool])->())) {
    let ref = Firestore.firestore(app: firebaseApp)
      .collection("antourage/\(Environment.current.rawValue)/streams/")
      .document("\(live.id)")
    ref.getDocument { (snapshot, _) in
      let chatOn = snapshot?.data()?["isChatActive"] as? Bool ?? false
      completion([live.id: chatOn])
    }
  }

  deinit {
    print("FB fetcher: DEINITED")
  }
}
