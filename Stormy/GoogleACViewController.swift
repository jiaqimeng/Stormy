//
//  GoogleACViewController.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/23/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import UIKit
import ChameleonFramework

protocol GoogleACViewControllerDelegate {
    func citySelected(cityCoordinate: (Double, Double))
}

class GoogleACViewController: UIViewController {
    
    var cityCoordinate: (Double, Double)?
    var delegate: GoogleACViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gpaViewController = GooglePlacesAutocomplete(
            apiKey: "AIzaSyAdbDColYfCzrDWiNtc7VqcqIjVQqWF0dc",
            placeType: .Cities
        )
        
        gpaViewController.placeDelegate = self
        presentViewController(gpaViewController, animated: true, completion: nil)
        gpaViewController.navigationItem.title = "Enter City"
        
        
        // Do any additional setup after loading the view.
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func unSetupVC() {
        
//        let secondViewController = storyboard!.instantiateViewControllerWithIdentifier("StormyViewController") as! StormyViewController
//        let transition: CATransition = CATransition()
//        transition.duration = 0.3
//        transition.type = kCATransitionFade
//        self.navigationController!.view.layer.addAnimation(transition, forKey: "kcTransition")
//        self.navigationController?.pushViewController(secondViewController, animated: false)
    }

}


extension GoogleACViewController: GooglePlacesAutocompleteDelegate {
    func placeSelected(place: Place) {
        
        place.getDetails { details in
            dispatch_async(dispatch_get_main_queue()) {
                self.cityCoordinate = (details.latitude, details.longitude)
                self.delegate?.citySelected(self.cityCoordinate!)
                self.dismissViewControllerAnimated(false) {
                    
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
        
        
    }
    
    func placeViewClosed() {
        dismissViewControllerAnimated(false) {
            self.dismissViewControllerAnimated(false) {
                
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        
    }
}