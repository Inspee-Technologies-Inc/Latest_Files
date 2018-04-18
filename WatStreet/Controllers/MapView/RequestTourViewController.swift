//
//  RequestTourViewController.swift
//  WatStreet
//
//  Created by star on 3/29/18.
//  Copyright © 2018 Eric Park. All rights reserved.
//

import UIKit
import SVProgressHUD

class RequestTourViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel1: UILabel!
    @IBOutlet weak var credLabel: UILabel!
    @IBOutlet weak var nameLabel2: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var iconButton: UIButton!
    
    @IBOutlet weak var reasonTextView: UITextView!
    @IBOutlet weak var textLengthLabel: UILabel!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    var feedInfo: FeedInfo!
    var userInfo: UserInfo!

    override func viewDidLoad() {
        super.viewDidLoad()

        if (feedInfo != nil) {
            titleLabel.text = feedInfo.feedType == "event" ? "REQUEST DEAL OR EVENT TOUR" : "REQUEST A SAFETY TOUR"
            nameLabel1.text = feedInfo.author
            nameLabel2.text = feedInfo.author
            credLabel.text = "Street Cred - \((feedInfo.userLiked)!)"
            summaryLabel.text = feedInfo.text
            addressLabel.text = " @ \((feedInfo.street)!)"
            placeholderLabel.text = "Tell \((feedInfo.author)!) why you want a live tour"
            if (feedInfo.feedType == "event") {
                iconButton.setImage(#imageLiteral(resourceName: "events_icon"), for: .normal)
            } else {
                iconButton.setImage(#imageLiteral(resourceName: "alert_icon"), for: .normal)
            }
        } else if (userInfo != nil) {
            titleLabel.text = "REQUEST A STREET VIEW"
            nameLabel1.text = userInfo.name
            nameLabel2.text = userInfo.name
            credLabel.text = "Street Cred - \((userInfo.liked)!)"
            summaryLabel.text = "\((userInfo.name)!) is available for a live street view"
            addressLabel.text = " @ \((userInfo.address)!)"
            placeholderLabel.text = "Tell \((userInfo.name)!) why you want a live tour"
            iconButton.setImage(#imageLiteral(resourceName: "adsfeeds_icon"), for: .normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UITextView Delegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text.count == 0) {
            return true
        } else if (text.count + (textView.text?.count)! <= 35) {
            return true
        } else {
            return false
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textLengthLabel.text = "\(String((reasonTextView.text?.count)!))/35"
        placeholderLabel.isHidden = textView.text.count > 0
    }
    
    // MARK: UI Events
    
    @IBAction func onSendTourRequest(_ sender: Any) {
        if (reasonTextView.text.count == 0) {
            SVProgressHUD.showError(withStatus: "Please input the reason.")
            return;
        }
        
        SVProgressHUD.show(withStatus: "Sending a tour request...")
        if (feedInfo != nil) {
            FeedManager.shared.addTourRequest(feedInfo: self.feedInfo, reason: reasonTextView.text) { (success, result) in
                if (success == false) {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showError(withStatus: result)
                } else {
                    SVProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        } else {
            FeedManager.shared.addTourUserRequest(userInfo: self.userInfo, reason: reasonTextView.text) { (success, result) in
                if (success == false) {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showError(withStatus: result)
                } else {
                    SVProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
