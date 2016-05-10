//
//  Student+CoreDataProperties.swift
//  SGT
//
//  Created by Kevin Clarke on 5/9/16.
//  Copyright © 2016 Northern illinois University. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Student {

    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var studentHas: NSSet?

}
