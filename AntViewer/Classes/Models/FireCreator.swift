//
//  FireCreator.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 09.12.2020.
//

import Foundation
import ViewerExtension

struct FireCreator: FirebaseCreator {
  func createPollManagerFor(streamId: Int, withPath path: String) -> PollManager {
    return FirePollManager(streamId: streamId, andPath: path)
  }
  
  func createChatFor(videoContent: VideoContent, andPath path: String) -> Chat {
    return FireChat(for: videoContent, andPath: path)
  }
  
  func createMessageFetcher(withPath path: String) -> FirebaseFetcher {
    return MessageFetcher(path: path)
  }
  
}
