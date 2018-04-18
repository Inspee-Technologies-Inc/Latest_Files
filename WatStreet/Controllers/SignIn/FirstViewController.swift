//
//  FirstViewController.swift
//  WatStreet
//
//  Created by Eric on 12/17/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    @IBOutlet weak var liveDealButton: UIButton!
    @IBOutlet weak var safetyAlertButton: UIButton!
    
    var curLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is EventPostViewController) {
            (segue.destination as! EventPostViewController).curLocation = self.curLocation
            (segue.destination as! EventPostViewController).isLiveDealEvent = ((sender as! UIButton) == liveDealButton)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: UI Events
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
