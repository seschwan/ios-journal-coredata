//
//  EntryController.swift
//  Journal Core Data
//
//  Created by Seschwan on 7/10/19.
//  Copyright © 2019 Seschwan. All rights reserved.
//

import Foundation
import CoreData

enum HTTPMethods: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
}

class EntryController {
    
    init() {
        self.fetchEntriesFromServer()
    }
    
    let baseURL = URL(string: "https://journalcoredata-446c0.firebaseio.com/")!
    
    //    var entries: [Entry] {
    //        return loadFromPersistentStore()
    //    }
    
    typealias CompletionHandler = (Error?) -> Void
    
    func put(entry: Entry, completion: @escaping CompletionHandler = { _ in }) {
        let uuid = entry.identifier ?? UUID().uuidString
        let requestURL = baseURL.appendingPathComponent(uuid).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethods.put.rawValue
        
        do {
            guard var representation = entry.entryRepresentation else {
                completion(NSError())
                return
            }
            
            representation.identifier = uuid
            entry.identifier = uuid
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("Error encoding entry: \(entry) \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error putting the entry to the server: \(error)")
                completion(error)
                return
            }
            completion(nil)
            }.resume()
    }
    
    func fetchEntriesFromServer(completion: @escaping CompletionHandler = { _ in }) {
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching entries: \(error)")
                completion(error)
                return
            }
            guard let data = data else { NSLog("No data was returned by the entry"); completion(error); return }
            
            do {
                let entryReps = Array(try JSONDecoder().decode([String : EntryRepresentation].self, from: data).values)
                let moc = CoreDataStack.shared.container.newBackgroundContext()
                try self.updateEntries(with: entryReps, context: moc)
                
                completion(nil)
            } catch {
                NSLog("Error decoding task representations: \(error)")
                completion(error)
                return
            }
        }.resume()
    }
    
    
    
    
    func saveToPersistentStore() {
        let moc = CoreDataStack.shared.mainContext
        do {
            try moc.save()
        } catch {
            moc.reset()
            NSLog("Error saving to core data: \(error)")
        }
    }
    
    //    func loadFromPersistentStore() -> [Entry] {
    //        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
    //        let moc = CoreDataStack.shared.mainContext
    //        do {
    //            let entries = try moc.fetch(fetchRequest)
    //            return entries
    //        } catch {
    //            NSLog("Error fetching the entries: \(error)")
    //        }
    //        return []
    //    }
    
    func fetchSingleEntryFromPersistentStore(uuid: String, context: NSManagedObjectContext) -> Entry? {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", uuid) // as UUID
        
        var result: Entry? = nil
        context.performAndWait {
            do {
                result = try context.fetch(fetchRequest).first
            } catch {
                NSLog("Error fetching entry with UUID \(uuid) \(error)")
            }
        }
        return result
    }
    
    private func updateEntries(with representations: [EntryRepresentation], context: NSManagedObjectContext) throws {
        var error: Error? = nil
        
        context.performAndWait {
            for entryRep in representations {
                let identifier = entryRep.identifier
                if let entry = self.fetchSingleEntryFromPersistentStore(uuid: identifier, context: context) {
                    self.update(entry: entry, representation: entryRep, context: context)
                } else {
                    let _ = Entry(entryRep: entryRep, context: context)
                }
            }
            
            do {
                try context.save()
            } catch let saveError {
                error = saveError
            }
        }
        if let error = error { throw error }
    }
    
    func createEntry(title: String, bodyText: String, mood: Moods) {
        let entry = Entry(title: title, bodyText: bodyText, mood: mood)
        put(entry: entry)
        saveToPersistentStore()
    }
    
    func update(entry: Entry, representation: EntryRepresentation, context: NSManagedObjectContext) {
        entry.title     = representation.title
        entry.bodyText  = representation.bodyText
        entry.mood      = representation.mood
        entry.timestamp = representation.timestamp
    }
    
    func updateEntry(entry: Entry, title: String, bodyText: String, timestamp: Date = Date(), mood: Moods) {
        entry.title     = title
        entry.bodyText  = bodyText
        entry.timestamp = timestamp
        entry.mood      = mood.rawValue
        put(entry: entry)
        saveToPersistentStore()
    }
    
    func deleteEntryFromServer(entry: Entry, completion: @escaping CompletionHandler = { _ in }) {
        guard let uuid = entry.identifier else {
            completion(NSError())
            return
        }
        let requestURL = baseURL.appendingPathComponent(uuid).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethods.delete.rawValue
        
        URLSession.shared.dataTask(with: request) { (_, response, error) in
            print(response!)
            completion(error)
            return
            }.resume()
    }
    
    func delete(entry: Entry) {
        self.deleteEntryFromServer(entry: entry) { (error) in
            if let error = error {
                NSLog("Error deleting entry from server: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                let moc = CoreDataStack.shared.mainContext
                moc.delete(entry)
                
                do {
                    try moc.save()
                } catch {
                    NSLog("Error saving after delete method")
                }
            }
        }
    }
}
