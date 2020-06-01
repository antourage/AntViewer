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
    @NSManaged public var messages: NSSet?
    @NSManaged public var polls: NSSet?

}

// MARK: Generated accessors for messages
extension VideoContentMO {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: MessageMO)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: MessageMO)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

// MARK: Generated accessors for polls
extension VideoContentMO {

    @objc(addPollsObject:)
    @NSManaged public func addToPolls(_ value: PollOM)

    @objc(removePollsObject:)
    @NSManaged public func removeFromPolls(_ value: PollOM)

    @objc(addPolls:)
    @NSManaged public func addToPolls(_ values: NSSet)

    @objc(removePolls:)
    @NSManaged public func removeFromPolls(_ values: NSSet)

}
