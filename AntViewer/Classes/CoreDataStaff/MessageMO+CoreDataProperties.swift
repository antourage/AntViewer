//
//  MessageMO+CoreDataProperties.swift
//  
//
//  Created by Maryan Luchko on 24.05.2020.
//
//

import Foundation
import CoreData


extension MessageMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageMO> {
        return NSFetchRequest<MessageMO>(entityName: "Message")
    }

    @NSManaged public var nickname: String
    @NSManaged public var text: String
    @NSManaged public var timestamp: Int64
    @NSManaged public var userId: String
    @NSManaged public var key: String
    @NSManaged public var content: VideoContentMO?

}
