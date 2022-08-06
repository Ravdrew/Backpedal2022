//
//  SavedNotes+CoreDataProperties.swift
//  NotesSaving
//
//  Created by Andres Garcia on 6/29/21.
//  Copyright © 2021 Andres Garcia. All rights reserved.
//
//

import Foundation
import CoreData


extension SavedNotes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedNotes> {
        return NSFetchRequest<SavedNotes>(entityName: "SavedNotes")
    }

    @NSManaged public var content: String?
    @NSManaged public var name: String?
    @NSManaged public var nval: Int32
    @NSManaged public var end_url: String?
    @NSManaged public var audio: Data?
    @NSManaged public var alerts: String?

}
