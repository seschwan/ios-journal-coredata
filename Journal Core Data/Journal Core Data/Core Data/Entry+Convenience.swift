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
    case meh = "😐"
    case sad = "😢"
}

extension Entry {
    convenience init(title: String, bodyText: String, timestamp: Date = Date(), identifier: String = UUID().uuidString, mood: String = Moods.meh.rawValue,  context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.title      = title
        self.bodyText   = bodyText
        self.timestamp  = timestamp
        self.identifier = identifier
        self.mood       = mood
        
    }
}
