//
//  Chat.swift
//  AntViewer
//
//  Created by Mykola Vaniurskyi on 6/7/19.
//

import Foundation
import Firebase
import ViewerExtension

final class FireChat: Chat {
  
  private var ref: DocumentReference?
  
  private var stateListener: ListenerRegistration?
  private var messagesListener: ListenerRegistration?
  
  public var onAdd: ((Message) -> ())?
  public var onRemove: ((Message) -> ())?
  public var onStateChange: ((Bool) -> ())?
  
  public init(for videoContent: VideoContent) {
    let contentMO = StorageManager.shared.loadVideoContent(content: videoContent)
    if contentMO.chatLoaded {
      DispatchQueue.main.asyncAfter(deadline: .now()+1) {
        contentMO.messages?.forEach({ self.onAdd?($0) })
      }
      return
    }
    let app = FirebaseApp.app(name: "AntViewerFirebase")!
    self.ref = Firestore.firestore(app: app).collection("antourage/\(Environment.current.rawValue)/streams").document("\(videoContent.id)")
    messagesListener = ref?.collection("messages").order(by: "timestamp").addSnapshotListener(messagesHandler())
    stateListener = ref?.addSnapshotListener(stateHandler())
  }
  
  deinit {
    stateListener?.remove()
    messagesListener?.remove()
    print("Chat delocated.")
  }
  
  private func messagesHandler() -> FIRQuerySnapshotBlock {
    return { [weak self] (querySnapshot, error) in
      guard let `self` = self else { return }
      guard let snapshot = querySnapshot else {
        print("Error fetching snapshots: \(error!)")
        return
      }
      snapshot.documentChanges.forEach { diff in
        switch diff.type {
        case .added:
          let data = diff.document.data()
          let date = (data["timestamp"] as? Timestamp)?.dateValue()
          let docID = diff.document.documentID
          print("New message: \(data)")
          if let message = Message(data: data, docID: docID, date: date) {
            self.onAdd?(message)
          }
        case .removed:
          let data = diff.document.data()
          let date = (data["timestamp"] as? Timestamp)?.dateValue()
          let docID = diff.document.documentID
          print("Removed message: \(data)")
          if let message = Message(data: data, docID: docID, date: date) {
            self.onRemove?(message)
          }
        default:
          break
        }
      }
    }
  }
  
  private func stateHandler() -> FIRDocumentSnapshotBlock {
    return { [weak self] (documentSnapshot, error) in
      guard let document = documentSnapshot?.data() else {
        print("Error fetching snapshots: \(String(describing: error))")
        return
      }
      let isActive = (document["isChatActive"] as? Bool) ?? false
      self?.onStateChange?(isActive)
    }
  }
  
  public func send(message: Message, withCompletionBlock: @escaping (Error?) -> ()) {
    ref?.collection("messages").addDocument(data: message.toAnyObject(), completion: { (error) in
      withCompletionBlock(error)
    })
  }
  
  
}


extension Message {
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
