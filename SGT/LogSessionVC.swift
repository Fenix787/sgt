//
//  LogSessionVC.swift
//  SGT
//
//  Created by Kevin Clarke on 4/8/16.
//  Copyright © 2016 Northern illinois University. All rights reserved.
//

import Foundation

import UIKit
import CoreData

class goalUISlider: UISlider {
    var step = Float(10)
    
    func setSliderStep(instep: Float) {
        step = instep
    }
}

class logSessionGoalCell: UITableViewCell {
    
    @IBOutlet weak var goalTitle: UILabel!
    @IBOutlet weak var goalSlider: goalUISlider!
    @IBOutlet weak var goalDescription: UILabel!
    @IBOutlet weak var goalSliderValueLabel: UILabel!
    
    
    
    @IBAction func goalSliderValueChanged(sender: goalUISlider) {
        if(sender.step != 0){
            let roundedValue = round(sender.value / sender.step) * sender.step
            sender.value = roundedValue
        }
        // update label value
        goalSliderValueLabel.text = NSString(format: "%.1f", sender.value) as String
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

class LogSessionVC: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var goalTableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        // save goal data
        var goalDataIndex = NSIndexPath(forRow: 0, inSection: 0)
        for goal in goals {
            let cell = self.goalTableView.cellForRowAtIndexPath(goalDataIndex) as! logSessionGoalCell
            saveGoalData(datePicker.date,goal: goal,value: cell.goalSlider.value)
            goalDataIndex = NSIndexPath(forRow:goalDataIndex.row+1, inSection:goalDataIndex.section)
        }
        // update graph view
        NSNotificationCenter.defaultCenter().postNotificationName("updateGraphView", object: nil)
        // dismiss view
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        // dismiss view
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var goals = [NSManagedObject]()
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            //self.configureView()
        }
    }
    
    func saveGoalData (date: NSDate, goal: NSManagedObject, value: Float) {
        let entity =  NSEntityDescription.entityForName("GoalData", inManagedObjectContext:managedObjectContext)
        let goalData = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
        
        // populate goalDate entity
        goalData.setValue(date, forKey: "date")
        goalData.setValue(goal, forKey: "dataFor")
        goalData.setValue(NSNumber(float: value), forKey: "value")
        
        do {
            try managedObjectContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.configureView()
        
        // load view
        _ = self.view
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count;
    }
    

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:logSessionGoalCell = self.goalTableView.dequeueReusableCellWithIdentifier("logSessionGoalCell")! as! logSessionGoalCell
        
        // code to fetch the last value for goal
        let entity =  NSEntityDescription.entityForName("GoalData", inManagedObjectContext:managedObjectContext)
        let request = NSFetchRequest()
        request.entity = entity
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        
        request.sortDescriptors = [sortDescriptor]
        request.fetchLimit = 1
        let pred = NSPredicate(format: "(dataFor= %@)", goals[indexPath.row])
        request.predicate = pred
        do {
            let results = try managedObjectContext.executeFetchRequest(request)
            if (results.count > 0) {
                cell.goalSlider.setValue(results[0].valueForKey("value") as! Float, animated: true)
            }
            cell.goalSliderValueLabel.text = NSString(format: "%.1f", cell.goalSlider.value) as String
        } catch {
            print("error populating slider")
        }
        
        let step = goals[indexPath.row].valueForKey("step")!
        cell.goalSlider.setSliderStep(step as! Float)
        cell.goalTitle.text = goals[indexPath.row].valueForKey("title") as? String
        cell.goalDescription.text = goals[indexPath.row].valueForKey("about") as? String
        
        return cell
    }
    

}