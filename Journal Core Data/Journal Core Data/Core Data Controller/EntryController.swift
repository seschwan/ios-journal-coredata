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
    
    func deleteEntryFromServer(entry: Entry, completion: @escaping CompletionHandler = { _ in }) {
        guard let uuid = entry.identifier else {
            completion(NSError())
            return
        }
        let requestURL = baseURL.appendingPathComponent(uuid).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethods.delete.rawValue
        
        URLSession.shared.dataTask(with: requestURL) { (_, response, error) in
            if let error = error {
                NSLog("Error deleting from server")
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
    
    func createEntry(title: String, bodyText: String, mood: Moods) {
        let entry = Entry(title: title, bodyText: bodyText, mood: mood)
        put(entry: entry)
        saveToPersistentStore()
    }
    
    func update(entry: Entry, title: String, bodyText: String, timestamp: Date = Date(), mood: Moods) {
        entry.title     = title
        entry.bodyText  = bodyText
        entry.timestamp = timestamp
        entry.mood      = mood.rawValue
        put(entry: entry)
        saveToPersistentStore()
    }
    
    func delete(entry: Entry) {
        let moc = CoreDataStack.shared.mainContext
        moc.delete(entry)
        deleteEntryFromServer(entry: entry)
        saveToPersistentStore()
    }
}
