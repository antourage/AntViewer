//
//  VideoContentMO+CoreDataProperties.swift
//  
//
//  Created by Maryan Luchko on 24.05.2020.
//
//

import Foundation
import CoreData
import AntViewerExt


extension VideoContentMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoContentMO> {
        return NSFetchRequest<VideoContentMO>(entityName: "VideoContent")
    }

    @NSManaged public var date: Date
    @NSManaged public var id: Int64
    @NSManaged public var latestMessage: LatestComment?
    @NSManaged public var stopTime: String
    @NSManaged public var chatLoaded: Bool
    @NSManaged public var latestCommentLoaded: Bool
    @NSManaged public var messagesMO: NSSet?
    @NSManaged public var pollsMO: NSSet?

  var messages: [Message]? {
    guard let messages = messagesMO?.allObjects as? [MessageMO] else {
      print("Error fetching chat")
      return nil
    }
    return messages.map { Message(userID: $0.userId, timestamp: Int($0.timestamp), nickname: $0.nickname, text: $0.text, key: $0.key) }.sorted { $0.timestamp < $1.timestamp }
  }
}

// MARK: Generated accessors for messagesMO
extension VideoContentMO {

    @objc(addMessagesMOObject:)
    @NSManaged public func addToMessagesMO(_ value: MessageMO)

    @objc(removeMessagesMOObject:)
    @NSManaged public func removeFromMessagesMO(_ value: MessageMO)

    @objc(addMessagesMO:)
    @NSManaged public func addToMessagesMO(_ values: NSSet)

    @objc(removeMessagesMO:)
    @NSManaged public func removeFromMessagesMO(_ values: NSSet)

}

// MARK: Generated accessors for pollsMO
extension VideoContentMO {

    @objc(addPollsMOObject:)
    @NSManaged public func addToPollsMO(_ value: PollMO)

    @objc(removePollsMOObject:)
    @NSManaged public func removeFromPollsMO(_ value: PollMO)

    @objc(addPollsMO:)
    @NSManaged public func addToPollsMO(_ values: NSSet)

    @objc(removePollsMO:)
    @NSManaged public func removeFromPollsMO(_ values: NSSet)

}
