//
//  Entry+Convenience.swift
//  Journal Core Data
//
//  Created by Seschwan on 7/10/19.
//  Copyright © 2019 Seschwan. All rights reserved.
//

import Foundation
import CoreData

enum Moods: String, CaseIterable {
    case happy = "😀"
    case meh   = "😐"
    case sad   = "😢"
}

extension Entry {
    convenience init(title: String, bodyText: String? = nil, timestamp: Date = Date(), identifier: String = UUID().uuidString, mood: Moods = .meh,  context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.title      = title
        self.bodyText   = bodyText
        self.timestamp  = timestamp
        self.identifier = identifier
        self.mood       = mood.rawValue
        
    }
    
    convenience init?(entryRep: EntryRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        guard let identifier = UUID(uuidString: entryRep.identifier),
            let mood = Moods(rawValue: entryRep.mood!) else { return nil }
        
        self.init(title: entryRep.title, bodyText: entryRep.bodyText, timestamp: entryRep.timestamp, identifier: identifier.uuidString, mood: mood)
    }
    
    var entryRepresentation: EntryRepresentation? {
        guard let title    = self.title,
            let timestamp  = self.timestamp,
            let mood       = self.mood,
            let identifier = self.identifier else { return nil }
        return EntryRepresentation(title: title, bodyText: bodyText, timestamp: timestamp, identifier: identifier, mood: mood)
    }
}
