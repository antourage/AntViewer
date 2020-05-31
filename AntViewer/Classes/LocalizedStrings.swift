//
//  LocalizedStrings.swift
//  AntViewer
//
//  Created by Maryan Luchko on 31.05.2020.
//

import Foundation

enum LocalizedStrings: String {
  //ERRORS
  case underMaintenance = "Under maintenance"
  case reopenWidget = "Unable to load. Please reopen widget"
  case failedToLoadVideo = "Failed to load video"
  case noConnection = "No connection"
  case youAreOnline = "You are online"
  case generalError = "Something is not right. We are working to get this fixed"
  //FEED
  case emptyDataSource = "Live interactive videos coming soon"
  case new = "New"
  case live = "LIVE"
  case mostRecent = "most recent"
  case joinConversation = "Join conversation"
  //CHAT
  case chat = "Chat"
  case joined = "Joined"
  case jumpToTop = "Jump to the top"
  case send = "Send"
  case chatDisabled = "Chat disabled"
  //DISPLAY NAME
  case yourChatName = "Your chat name"
  case typeDisplayName = "Type your display name"
  case save = "Save"
  case cancel = "Cancel"
  //POOLS
  case voteToSeeResults = "Vote to see results!"
  case thanksForVoting = "Thanks for voting!"
  case vote = "Vote"
  //OTHER
  case justNow = "Just now"
  case thanksForWatching = "THANKS FOR WATCHING"
  case chooseLink = "Choose link"
  case set = "set"
}

extension LocalizedStrings {
  var localized: String {
    return self.rawValue.localized()
  }
}
