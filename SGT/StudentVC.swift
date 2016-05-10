//
//  DetailViewController.swift
//  SGT
//
//  Created by Kevin Clarke on 4/8/16.
//  Copyright © 2016 Northern illinois University. All rights reserved.
//

import UIKit
import CoreData
import Charts

class StudentVC: UIViewController, NSFetchedResultsControllerDelegate, ChartViewDelegate {

    @IBOutlet weak var segmentedGoal: UISegmentedControl!
    @IBOutlet weak var goalChart: LineChartView!
    @IBOutlet weak var goalDescriptionLabel: UILabel!
    
    @IBAction func goalSelectedChanged(sender: UISegmentedControl) {
        //if(deleteGoalButton.hidden == true) {
        //    deleteGoalButton.hidden = false
        //}
        
        goalDescriptionLabel.text = goals[segmentedGoal.selectedSegmentIndex].valueForKey("about")! as? String
        populateGraphData(goals[segmentedGoal.selectedSegmentIndex])
    }
    
    
    
   
    var logSessionViewController: LogSessionVC? = nil
    
    var goals = [NSManagedObject]()
    var goalIndex = 0

    var rightNewBarButtonItem:UIBarButtonItem = UIBarButtonItem()
    var rightLogSessionBarButtonItem:UIBarButtonItem = UIBarButtonItem()
    var leftDeleteBarButtonItem:UIBarButtonItem = UIBarButtonItem()
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    


    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            self.title = detail.valueForKey("firstName")!.description + " " + detail.valueForKey("lastName")!.description
            
            // load view
            _ = self.view
            
            self.navigationItem.setRightBarButtonItems([rightNewBarButtonItem], animated: true)
            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
            goalDescriptionLabel.text = ""
            goalChart.delegate = self
            
            goalChart.descriptionText = ""
            goalChart.noDataTextDescription = "Select a goal to view graph."

            //goalChart.maxVisibleValueCount = 10
            goalChart.pinchZoomEnabled = false
            goalChart.drawGridBackgroundEnabled = true
            goalChart.drawBordersEnabled = false
            goalChart.xAxis.labelPosition = .Bottom
            goalChart.backgroundColor = UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: 1)

            populateGoals()
            
            // select the first goal in the list
            if(goals.count > 0){
                segmentedGoal.selectedSegmentIndex = 0
                goalDescriptionLabel.text = goals[0].valueForKey("about")! as? String
                populateGraphData(goals[0])
                self.navigationItem.setLeftBarButtonItems([leftDeleteBarButtonItem], animated: true)
                self.navigationItem.setRightBarButtonItems([rightNewBarButtonItem,rightLogSessionBarButtonItem], animated: true)
                print(self.navigationItem.leftBarButtonItems)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // setup reload graph listener
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateGraphView), name: "updateGraphView", object: nil)
        
        // load buttons
        rightNewBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(newGoal))
        rightLogSessionBarButtonItem = UIBarButtonItem(title: "Log Session", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(logSession))
        leftDeleteBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(deleteGoal))
        
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveGoal(title: String, about: String, step: Float) {
        let entity =  NSEntityDescription.entityForName("Goal", inManagedObjectContext:managedObjectContext)
        
        let goal = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
        goal.setValue(title, forKey: "title")
        goal.setValue(about, forKey: "about")
        goal.setValue(step as AnyObject, forKey: "step")
        goal.setValue(detailItem, forKey: "goalFor")
        
        do {
            try managedObjectContext.save()
            goals.append(goal)
            segmentedGoal.insertSegmentWithTitle(title, atIndex: goalIndex, animated: true)
            goalIndex += 1
        } catch {
            print("error saving goal")
        }
    }
    
    
    func populateGoals() {
        let entityDescription = NSEntityDescription.entityForName("Goal", inManagedObjectContext: self.managedObjectContext)
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        let pred = NSPredicate(format: "(goalFor= %@)", (detailItem?.objectID)!)
        request.predicate = pred
        
        // clear segmented control
        segmentedGoal.removeAllSegments()
        
        do {
            let results = try managedObjectContext.executeFetchRequest(request)
            goals = results as! [NSManagedObject]
            goalIndex = 0
            for result in results {
                segmentedGoal.insertSegmentWithTitle(result.valueForKey("title") as? String, atIndex: goalIndex, animated: true)
                goalIndex += 1
            }
            
        } catch {
            print("error fetching results")
        }
    }
    
    func populateGraphData(goal: NSManagedObject) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "d MMM HH:mm"
        var dataEntries: [ChartDataEntry] = []
        var dateEntries: [String] = []

        let entityDescription = NSEntityDescription.entityForName("GoalData", inManagedObjectContext: self.managedObjectContext)

        let request = NSFetchRequest()
        request.entity = entityDescription
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        let pred = NSPredicate(format: "(dataFor= %@)", (goal.objectID))
        request.predicate = pred
        
        do {
            let results = try managedObjectContext.executeFetchRequest(request)
            var goalDataIndex = 0
            for result in results {
                let value = Double(result.valueForKey("value") as! NSNumber)
                let dataEntry = ChartDataEntry(value: value, xIndex: goalDataIndex)
                dataEntries.append(dataEntry)
                dateEntries.append(formatter.stringFromDate(result.valueForKey("date")! as! NSDate))
                goalDataIndex += 1
            }
            
        } catch {
            print("error fetching results")
        }
        
        // create a data set with array
        let set1: LineChartDataSet = LineChartDataSet(yVals: dataEntries, label: goal.valueForKey("title") as? String)
        set1.axisDependency = .Left // Line will correlate with left axis values
        set1.setColor(UIColor.redColor().colorWithAlphaComponent(0.5)) // our line's opacity is 50%
        set1.setCircleColor(UIColor.redColor()) // our circle will be dark red
        set1.lineWidth = 2.0
        set1.circleRadius = 6.0 // the radius of the node circle
        set1.fillAlpha = 65 / 255.0
        set1.fillColor = UIColor.redColor()
        set1.highlightColor = UIColor.whiteColor()
        set1.drawCircleHoleEnabled = true
        
        // create an array to store LineChartDataSets
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(set1)
        
        // pass months in for x-axis label value along with dataSets
        let data: LineChartData = LineChartData(xVals: dateEntries, dataSets: dataSets)
        data.setValueTextColor(UIColor.blackColor())
        
        // finally set data
        self.goalChart.data = data
        
    }
    
    func updateGraphView() {
        populateGraphData(goals[segmentedGoal.selectedSegmentIndex])
    }
    
    func logSession() {
        self.performSegueWithIdentifier("logSession", sender: self)
    }
    
    func newGoal() {
        // alert view
        let alertController = UIAlertController(
            title: "New Goal",
            message: "Please enter a descriptive title for this goal.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addTextFieldWithConfigurationHandler {
            (fname) -> Void in
            fname.placeholder = "Goal Title"
        }
        
        alertController.addTextFieldWithConfigurationHandler {
            (fname) -> Void in
            fname.placeholder = "Goal Description"
        }
        
        alertController.addTextFieldWithConfigurationHandler {
            (fname) -> Void in
            fname.placeholder = "Step Size"
        }
        
        let okAction = UIAlertAction(
        title: "OK", style: UIAlertActionStyle.Default) {
            (action) -> Void in
            let title = alertController.textFields?[0].text!
            let about = alertController.textFields?[1].text!
            let step = NSString(string: (alertController.textFields?[2].text!)!).floatValue
            self.saveGoal(title!,about: about!,step: step)
            if(self.goals.count > 0) {
                self.navigationItem.setRightBarButtonItems([self.rightNewBarButtonItem,self.rightLogSessionBarButtonItem], animated: true)
                self.navigationItem.setLeftBarButtonItems([self.leftDeleteBarButtonItem], animated: true)
                self.segmentedGoal.selectedSegmentIndex = 0
                self.goalSelectedChanged(self.segmentedGoal)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in}
        
        // Display alert view
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func deleteGoal() {
        if (segmentedGoal.selectedSegmentIndex != UISegmentedControlNoSegment) {
        
            // alert view
            let alertController = UIAlertController(
                title: "Delete Goal",
                message: "Are you sure you want to delete this goal and all of its data?",
                preferredStyle: UIAlertControllerStyle.Alert)
        
        
            let okAction = UIAlertAction(
            title: "OK", style: UIAlertActionStyle.Default) {
                (action) -> Void in
                let request = NSFetchRequest(entityName: "GoalData")
                request.includesSubentities = false
                request.returnsObjectsAsFaults = false
            
                let pred = NSPredicate(format: "(dataFor= %@)", self.goals[self.segmentedGoal.selectedSegmentIndex])
                request.predicate = pred
                do {
                    let goalData = try self.managedObjectContext.executeFetchRequest(request)
                
                    for data in goalData {
                        self.managedObjectContext.deleteObject(data as! NSManagedObject)
                    }
                } catch {
                    print ("Error removing goal data")
                }
            
                self.managedObjectContext.deleteObject(self.goals[self.segmentedGoal.selectedSegmentIndex])
                self.appDelegate.saveContext()
            
                self.configureView()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in}
            
            // Display alert view
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "logSession" {
                let controller = segue.destinationViewController as! LogSessionVC
                controller.detailItem = detailItem
                controller.goals = goals
            }
    }
    
}

