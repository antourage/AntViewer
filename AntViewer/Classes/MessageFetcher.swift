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
    let settings = FirestoreSettings()
    settings.isPersistenceEnabled = false
    let db = Firestore.firestore()
    db.settings = settings
  }

  func fetchLatestMessagesFor(VODs: [VOD], completion: @escaping(([Int: LatestComment])->())) {
    var latestComments = Dictionary<Int, LatestComment>()
    let group = DispatchGroup()
    for video in VODs {
      getLatestMessageFor(video: video, group: group, completion: { infoDict in
        latestComments.merge(infoDict, uniquingKeysWith: { (_, updated) in updated  })
      })
    }
    group.notify(queue: .main) {
      completion((latestComments))
    }
  }

  func fetchInfoFor(lives: [Live], completion: @escaping(([Int: (LatestComment?, pollOn: Bool?, chanOn: Bool?)])->())) {
    var liveInfo = Dictionary<Int, (LatestComment?, Bool?, Bool?)>()
    lives.forEach { liveInfo[$0.id] = (nil, nil, nil) }
    let group = DispatchGroup()

    for video in lives {
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
      completion((liveInfo))
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

    group.enter()
    ref.getDocuments { (snapshot, error) in
      if let json = snapshot?.documents.first?.data(),
        let nickname = json["nickname"] as? String,
        let text = json["text"] as? String {
        completion([video.id : LatestComment(nickname: nickname, text: text, timestamp: nil)])
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
