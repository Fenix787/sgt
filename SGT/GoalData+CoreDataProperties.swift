//
//  GoalData+CoreDataProperties.swift
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

extension GoalData {

    @NSManaged var date: NSDate?
    @NSManaged var value: NSNumber?
    @NSManaged var dataFor: Goal?

}
