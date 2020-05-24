//
//  PollOM+CoreDataProperties.swift
//  
//
//  Created by Maryan Luchko on 24.05.2020.
//
//

import Foundation
import CoreData


extension PollOM {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PollOM> {
        return NSFetchRequest<PollOM>(entityName: "Poll")
    }

    @NSManaged public var key: String
    @NSManaged public var userAnswer: Int
    @NSManaged public var pollQuestion: String
    @NSManaged public var pollAnswers: [Int]?
    @NSManaged public var content: VideoContentMO

}
