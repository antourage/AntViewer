//
//  PollMO+CoreDataProperties.swift
//  
//
//  Created by Maryan Luchko on 24.05.2020.
//
//

import Foundation
import CoreData


extension PollMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PollMO> {
        return NSFetchRequest<PollMO>(entityName: "Poll")
    }

    @NSManaged public var key: String?
    @NSManaged public var pollAnswers: [NSNumber]?
    @NSManaged public var pollQuestion: String?
    @NSManaged public var userAnswer: NSNumber?
    @NSManaged public var content: VideoContentMO?

}
