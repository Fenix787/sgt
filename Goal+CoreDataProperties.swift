//
//  Goal+CoreDataProperties.swift
//  SGT
//
//  Created by Kevin Clarke on 5/8/16.
//  Copyright © 2016 Northern illinois University. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Goal {

    @NSManaged var title: String?
    @NSManaged var for: NSManagedObject?
    @NSManaged var has: NSSet?

}
