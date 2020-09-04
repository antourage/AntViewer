//
//  MessageFetcher.swift
//  AntViewer
//
//  Created by Maryan Luchko on 14.05.2020.
//

import Foundation
import Firebase
import AntViewerExt

class MessageFetcher: FirebaseFetcher {

  var firebaseApp: FirebaseApp

  init() {
    self.firebaseApp = FirebaseApp.app(name: "AntViewerFirebase")!
  }

  func setLatestMessagesTo(VODs: [VOD], completion: @escaping(([VOD])->())) {
     let group = DispatchGroup()
     let editedVODs = VODs
     for video in editedVODs {
       group.enter()
       let vodFromCache = StorageManager.shared.loadVideoContent(content: video)
       if vodFromCache.latestCommentLoaded {
         video.latestMessage = vodFromCache.latestMessage
         group.leave()
       } else {
         getLatestMessageFor(video: video, group: group, completion: { infoDict in
           let latestComment = infoDict[video.id]
           video.latestMessage = latestComment
           StorageManager.shared.saveLatestComment(for: video, value: latestComment)
         })
       }
     }

     group.notify(queue: .main) {
       completion((editedVODs))
     }
  }



  func setInfoTo(lives: [Live], completion: @escaping(([Live])->())) {
    var liveInfo = Dictionary<Int, (LatestComment?, Bool, Bool)>()
    lives.forEach { liveInfo[$0.id] = (nil, false, false) }
    let group = DispatchGroup()

    for video in lives {
      group.enter()
      getLatestMessageFor(video: video, group: group, completion: { infoDict in
        liveInfo[video.id]?.0 = infoDict[video.id]
      })

      checkPollStatus(live: video, group: group, completion: { infoDict in
          liveInfo[video.id]?.1 = infoDict[video.id] ?? false
      })

      checkChatState(live: video, group: group) { (infoDict) in
          liveInfo[video.id]?.2 = infoDict[video.id] ?? false
      }
    }

    group.notify(queue: .main) {
      let editedLives = lives.map { (content) -> Live in
            var content = content
            content.latestMessage = liveInfo[content.id]?.0
            content.isPollOn = liveInfo[content.id]?.1 ?? false
            content.isChatOn = liveInfo[content.id]?.2 ?? false
            return content
          }
      completion((editedLives))
    }
  }

  private func getLatestMessageFor(video: VideoContent, group: DispatchGroup, completion: @escaping(([Int: LatestComment])->())) {
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
      group.leave()
    }
  }

  private func checkPollStatus(live: VideoContent, group: DispatchGroup, completion: @escaping(([Int: Bool])->())) {
    let ref = Firestore.firestore(app: firebaseApp)
      .collection("antourage/\(Environment.current.rawValue)/streams/\(live.id)/polls")
      .whereField("isActive", isEqualTo: true)
    group.enter()
    ref.getDocuments { (snapshot, _) in
      completion([live.id: !(snapshot?.documents.isEmpty ?? true)])
      group.leave()
    }
  }

  private func checkChatState(live: VideoContent, group: DispatchGroup, completion: @escaping(([Int: Bool])->())) {
    let ref = Firestore.firestore(app: firebaseApp)
      .collection("antourage/\(Environment.current.rawValue)/streams/")
      .document("\(live.id)")
    group.enter()
    ref.getDocument { (snapshot, _) in
      let chatOn = snapshot?.data()?["isChatActive"] as? Bool ?? false
      completion([live.id: chatOn])
      group.leave()
    }
  }

  deinit {
    print("FB fetcher: DEINITED")
  }
}
