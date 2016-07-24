//
//  UISideMenuTableViewController.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/21/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import UIKit
import ChameleonFramework

class UISideMenuTableViewController: UITableViewController, ElasticMenuTransitionDelegate  {
    
    var contentLength:CGFloat = 320
    var dismissByBackgroundTouch = true
    var dismissByBackgroundDrag = true
    var dismissByForegroundDrag = true
    
    
    var transition = ElasticTransition()
    
    var cities = [CityInfo]()
    var tempUnitFaren = true
    
    struct Storyboard {
        static let CellReuseID = "City"
        static let ChangeCitySegue = "ChangeCitySegue"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset.top = 20
        transition.edge = .Right
        transition.sticky = false
        transition.radiusFactor = 0
        let darkBlur = UIBlurEffect(style: .Dark)
        let darkBlurView = UIVisualEffectView(effect: darkBlur)
        darkBlurView.frame = self.view.bounds
        self.view.clipsToBounds = true
//        self.view.insertSubview(darkBlurView, atIndex: 0)
        
        darkBlurView.clipsToBounds = true
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseID, forIndexPath: indexPath) as! UISideMenuTableViewCell
        cell.tempUnitFaren = tempUnitFaren
        cell.city = cities[indexPath.row]
        cell.allowsMultipleSwipe = true
        if indexPath.row != 0 {
            cell.rightButtons = [MGSwipeButton(title: "Delete", backgroundColor: UIColor.redColor(), callback: {
                (sender: MGSwipeTableCell!) -> Bool in
                self.cities.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
                tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.None)
                saveCitiesData(self.cities)
                return true
            })]
            
        } else {
            cell.rightButtons = [MGSwipeButton()]
            cell.isCurrentLocation = true
        }
        
        // Configure the cell...
        
        return cell
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Storyboard.ChangeCitySegue {
            if let dstVC = segue.destinationViewController as? StormyViewController {
                let cellIndex = self.tableView.indexPathForSelectedRow
                if let index = cellIndex?.row {
                    if index == 0 {
                        dstVC.isCurrentLocation = true
                        // mark July 11, we do not want the current location page refresh from nothing
                        dstVC.cityInfo = cities[cellIndex!.row]
                    } else {
                        dstVC.isCurrentLocation = false
                        dstVC.cityInfo = cities[cellIndex!.row]
                    }
                    dstVC.setUnit(tempUnitFaren)
                    dstVC.transitioningDelegate = transition
                    dstVC.modalPresentationStyle = .Custom
                }
                
                
            }
        }
    }
    
    

}
