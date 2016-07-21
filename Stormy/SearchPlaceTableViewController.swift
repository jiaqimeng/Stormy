//
//  SearchPlaceTableViewController.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/22/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import UIKit
import Alamofire

class SearchPlaceTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    
    var resultSearchController:UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let searchBar = self.resultSearchController?.searchBar {
            resultSearchController?.active = true
            print(searchBar.becomeFirstResponder())
        }
    }
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
    }
    
    func setupSearchBar() {
        let searchPlaceTable = storyboard!.instantiateViewControllerWithIdentifier("SearchPlaceTable") as! SearchPlaceTableViewController
        resultSearchController = UISearchController(searchResultsController: searchPlaceTable)
        resultSearchController?.searchResultsUpdater = self
        resultSearchController?.delegate = self
        let searchBar = resultSearchController!.searchBar
        searchBar.becomeFirstResponder()
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for city name"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in }) { (completed) -> Void in
            
            searchController.searchBar.becomeFirstResponder()
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        let secondViewController = storyboard!.instantiateViewControllerWithIdentifier("StormyViewController") as! StormyViewController
        
        let transition: CATransition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionFade
        self.navigationController!.view.layer.addAnimation(transition, forKey: "kcTransition")
        self.navigationController?.pushViewController(secondViewController, animated: false)
        
        // Stop doing the search stuff
        // and clear the text in the search bar
        
        // You could also change the position, frame etc of the searchBar
    }
    
    
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
