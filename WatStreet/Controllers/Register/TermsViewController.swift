//
//  TermsViewController.swift
//  WatStreet
//
//  Created by Eric on 1/27/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import SVProgressHUD
import SkyFloatingLabelTextField

class TermsViewController: UIViewController {
    
    @IBOutlet weak var termsWebView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "terms", withExtension: "html")
        
        do {
            let html = try String.init(contentsOf: url!)
            termsWebView.loadHTMLString(html, baseURL: nil)
        } catch let error {
            print ("\(error)")
        }
    }
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
