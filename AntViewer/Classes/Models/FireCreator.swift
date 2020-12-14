//
//  FireCreator.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 09.12.2020.
//

import Foundation
import ViewerExtension

struct FireCreator: FirebaseCreator {
  func createPollManagerFor(streamId: Int) -> PollManager {
    return FirePollManager(streamId: streamId)
  }
  
  func createChatFor(videoContent: VideoContent) -> Chat {
    return FireChat(for: videoContent)
  }
  
  func createMessageFetcher() -> FirebaseFetcher {
    return MessageFetcher()
  }
  
}
