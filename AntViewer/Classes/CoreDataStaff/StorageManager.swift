//
// StorageManager.swift
// AntViewer
//
// Created by Maryan Luchko on 23.05.2020.
//
//
import Foundation
import CoreData      
import ViewerExtension

public class StorageManager {

  private let databaseName = "AntViewerModel"

  private lazy var persistentContainer: NSPersistentContainer = {
    let modelURL = Bundle(for: type(of: self)).url(forResource: databaseName, withExtension: "momd")

    guard let model = modelURL.flatMap(NSManagedObjectModel.init) else {
      fatalError("Fail to load model!")
    }
    var container: AntPersistentContainer

    container = AntPersistentContainer(name: databaseName, managedObjectModel: model)
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        print("Unexpected error: \(error), \(error.userInfo)")
      } else if let error = error {
        print("Unexpected error: \(error)")
      }
    })
    return container
  }()


  private var managedObjectContext: NSManagedObjectContext?

  private init() {
    managedObjectContext = persistentContainer.viewContext

    guard managedObjectContext != nil else {
      print("Cann't get right managed object context.")
      return
    }
    deleteExpiredContent()
    NotificationCenter.default.addObserver(self, selector: #selector(deleteAll), name: NSNotification.Name("EnvironmentChanged"), object: nil)
  }
  static var shared = StorageManager()

  private func saveContext () {
    let context = persistentContainer.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }

  private func videoContentMO(for content: VideoContent) -> VideoContentMO {
    defer { saveContext() }
    let contentMO = VideoContentMO(context: persistentContainer.viewContext)
    contentMO.id = Int64(content.id)
    contentMO.date = content.date
    return contentMO
  }
}

// Set correct persistent container
extension StorageManager {
  class AntPersistentContainer: NSPersistentContainer {
    override open class func defaultDirectoryURL() -> URL {
      let urlForApplicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

      let url = urlForApplicationSupportDirectory.appendingPathComponent("AntViewerDB")

      if FileManager.default.fileExists(atPath: url.path) == false {
        do {
          try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
          print("Can not create storage folder!")
        }
      }
      return url
    }
  }

   func loadVideoContent(content: VideoContent) -> VideoContentMO {
    let request: NSFetchRequest<VideoContentMO> = VideoContentMO.fetchRequest()
    request.predicate = NSPredicate(format: "id == %d", content.id)
    do {
      if let loadedContent = try persistentContainer.viewContext.fetch(request).first {
        return loadedContent
      }
    } catch let error {
      print("Error fetching video content: \(error.localizedDescription)")
    }
    return videoContentMO(for: content)
  }

  private func deleteExpiredContent() {
    guard let date = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) else { return }
    let request: NSFetchRequest<VideoContentMO> = VideoContentMO.fetchRequest()
    let predicate = NSPredicate(format: "date < %@", date as NSDate)
    request.predicate = predicate
    do {
      try persistentContainer.viewContext.fetch(request).forEach {
        persistentContainer.viewContext.delete($0)
      }
      saveContext()
    } catch let error {
      print("Error fetching video content: \(error.localizedDescription)")
    }
  }
  
  @objc
  private func deleteAll() {
    let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "VideoContent")
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
    do {
        try persistentContainer.viewContext.execute(deleteRequest)
        saveContext()
    } catch {
        print ("There was an error")
    }
  }
}

//methods to
public extension StorageManager {
  func loadStoptime(for videoContent: VideoContent) -> String {
    return loadVideoContent(content: videoContent).stopTime
  }

  func saveStoptime(for videoContent: VideoContent, value: String) {
    defer { saveContext() }
    let contentToSave = loadVideoContent(content: videoContent)
    contentToSave.stopTime = value
  }

  func saveLatestComment(for videoContent: VideoContent, value: LatestComment?) {
    defer { saveContext() }
    let contentToSave = loadVideoContent(content: videoContent)
    contentToSave.latestMessage = value
    contentToSave.latestCommentLoaded = true
  }

  func saveChat(for videoContent: VideoContent, value: [Message]) {
    defer { saveContext() }
    let contentToSave = loadVideoContent(content: videoContent)
    guard !contentToSave.chatLoaded else { return }
    let messagesMO = value.map { (message) -> MessageMO in
     let messageMO = MessageMO(context: persistentContainer.viewContext)
      messageMO.nickname = message.nickname
      messageMO.text = message.text
      messageMO.timestamp = Int64(message.timestamp)
      messageMO.userId = message.userID
      messageMO.key = message.key
      messageMO.content = contentToSave
      return messageMO
    }
    contentToSave.addToMessagesMO(NSSet(array: messagesMO))
    if videoContent is VOD {
      contentToSave.chatLoaded = true
    }
  }

  func savePolls(for videoContent: VideoContent, value: [Poll]) {
    //TODO: save polls for vod/live
  }

}

public extension VOD {
  var stopTime: String {
    get {
      StorageManager.shared.loadStoptime(for: self)
    }
    set {
      StorageManager.shared.saveStoptime(for: self, value: newValue)
    }
  }
}

@available(iOS 12.0, *)
@objc(AntValueTransformer)
final class AntValueTransformer: NSSecureUnarchiveFromDataTransformer {

    static let name = NSValueTransformerName(rawValue: String(describing: AntValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
      return [LatestComment.self, NSNumber.self]
    }

    public static func register() {
        let transformer = AntValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
