//
//  FireCreator.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 09.12.2020.
//

import Foundation
import ViewerExtension

struct FireCreator: FirebaseCreator {
  func createPollManager(streamId: Int, path: String) -> PollManager {
    return FirePollManager(streamId: streamId, path: path)
  }
  
  func createChat(videoContent: VideoContent, path: String) -> Chat {
    return FireChat(videoContent: videoContent, path: path)
  }
  
  func createMessageFetcher(path: String) -> FirebaseFetcher {
    return MessageFetcher(path: path)
  }
  
}
