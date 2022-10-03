//
//  ActivityLocal+CoreDataClass.swift
//
//
//  Created by Carolina Ortega on 13/09/22.
//
//

import Foundation
import CoreData

class ActivityRepository {
    static let shared: ActivityRepository = ActivityRepository()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "macroChallengeApp")
        container.loadPersistentStores { _, error in
            if let erro = error {
                preconditionFailure(erro.localizedDescription)
            }
            
        }
        return container
    }()
    
    var context = RoadmapRepository.shared.context
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Problema de contexto: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func createActivity(day: DayLocal, activity: Activity) -> ActivityLocal {
        guard let newActivity = NSEntityDescription.insertNewObject(forEntityName: "ActivityLocal", into: context) as? ActivityLocal else { preconditionFailure() }
        
        newActivity.id = Int32(activity.id)
        newActivity.name = activity.name
        newActivity.category = activity.category
        newActivity.location = activity.location
        newActivity.hour = activity.hour
        newActivity.budget = activity.budget
        
        day.addToActivity(newActivity)

        self.saveContext()
        return newActivity
    }
    func copyActivity(day: DayLocal, activity: ActivityLocal) {
        guard let newActivity = NSEntityDescription.insertNewObject(forEntityName: "ActivityLocal", into: context) as? ActivityLocal else { preconditionFailure() }
        
        newActivity.id = activity.id
        newActivity.name = activity.name
        newActivity.category = activity.category
        newActivity.location = activity.location
        newActivity.hour = activity.hour
        newActivity.budget = activity.budget
        
        day.addToActivity(newActivity)

        self.saveContext()
    }
    func getActivity() -> [ActivityLocal] {
        let fetchRequest = NSFetchRequest<ActivityLocal>(entityName: "ActivityLocal")
        do {
            return try self.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print(error)
        }
        return []
    }
    
    func deleteActivity(activity: ActivityLocal) throws {
        guard let context = activity.managedObjectContext else { return }

        if context == self.persistentContainer.viewContext {
          context.delete(activity)
        } else {
            self.persistentContainer.performBackgroundTask { context in
          context.delete(activity)
        }
      }
      try? self.persistentContainer.viewContext.save()
    }
}
