//
//  Poll.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/17/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import Foundation
import Firebase
import ViewerExtension

final class FirePoll: Poll {
  
  private var ref: DocumentReference?
  private var answersListener: ListenerRegistration?
  private var deviceID: String
  public var key: String
  public var userAnswer: Int?
  public var pollQuestion: String
  public var pollAnswers: [String]
  public var answersCount: [Int] {
    didSet {
      percentForEachAnswer = FirePoll.calculatePercentages(answersCount)
    }
  }
  
  public var onUpdate: (() -> ())?
  
  public var percentForEachAnswer: [Int] {
    didSet {
      self.onUpdate?()
    }
  }
  
  public init?(snapshot: DocumentSnapshot, deviceID: String) {
    guard
      let value = snapshot.data(),
      let pollQuestion = value["question"] as? String,
      let pollAnswers = value["answers"] as? [String] else {
        return nil
    }
    self.deviceID = deviceID
    self.ref = snapshot.reference
    self.key = snapshot.documentID
    self.pollQuestion = pollQuestion
    self.pollAnswers = pollAnswers
    self.percentForEachAnswer = pollAnswers.map {_ in 0}
    self.answersCount = pollAnswers.map {_ in 0}
    if deviceID == snapshot.documentID {
      self.userAnswer = value["chosenAnswer"] as? Int
    }
    answersListener = ref?.collection("answeredUsers").addSnapshotListener(answersHandler())
    
  }
  
  deinit {
    answersListener?.remove()
    print("Active poll deinited")
  }
  
  private static func calculatePercentages(_ pollAnswers: [Int]) -> [Int] {
    let sum = pollAnswers.reduce(0, +)
    if sum == 0 {
      return pollAnswers
    }
    let percentageArray = pollAnswers.map {100 * $0/sum}
    let arrayWithoutZero = percentageArray.filter {$0 != 0}
    let delta = percentageArray.reduce(100, -)
    if Set(arrayWithoutZero).count == 1 {
      return percentageArray
    }
    let firstElement = arrayWithoutZero[0]
    let number = arrayWithoutZero.dropFirst().contains(firstElement) ? arrayWithoutZero.first(where: {$0 != firstElement}) ?? firstElement : firstElement
    let count = arrayWithoutZero.filter {$0 == number}.count
    let a = delta/count
    return percentageArray.map {$0 == number ? $0 + a : $0}
  }
  
  private func answersHandler() -> FIRQuerySnapshotBlock {
    return { [weak self] (querySnapshot, error) in
      guard let documents = querySnapshot?.documents else {
        print("Error fetching documents: \(error!)")
        return
      }
      
      if let deviceID = self?.deviceID {
        let userDocument = documents.first(where: { $0.documentID == "\(deviceID)" })
        self?.userAnswer = userDocument?.data()["chosenAnswer"] as? Int
      }
      let answers = documents.compactMap {$0.data()["chosenAnswer"] as? Int}
      let answersDict = Dictionary(grouping: answers, by: {$0})
      var result = [Int]()
      self?.pollAnswers.enumerated().forEach {
        let answersPerQuestion = answersDict[$0.offset]?.count
        result.append(answersPerQuestion ?? 0)
      }
      self?.answersCount = result
    }
  }
  
  public func saveAnswer(index: Int, deviceID: String) {
    ref?.collection("answeredUsers").document("\(deviceID)").setData(["chosenAnswer": index, "timestamp": FieldValue.serverTimestamp()])
  }
  
}


