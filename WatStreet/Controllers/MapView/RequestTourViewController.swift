//
//  RequestTourViewController.swift
//  WatStreet
//
//  Created by star on 3/29/18.
//  Copyright © 2018 Eric Park. All rights reserved.
//

import UIKit
import SVProgressHUD

class RequestTourViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
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
    
    @IBOutlet weak var tourToAllButton: UIButton!
    @IBOutlet weak var tourToOnlyButton: UIButton!
    @IBOutlet weak var tourToView: UIView!
    
    @IBOutlet weak var expireHourLabel: UILabel!
    @IBOutlet weak var expireMinLabel: UILabel!
    @IBOutlet weak var expireTextField: UITextField!
    @IBOutlet weak var tourToHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topMargin1: NSLayoutConstraint!
    @IBOutlet weak var topMargin2: NSLayoutConstraint!
    
    var expiration: TimeInterval = 23 * 3600 + 59 * 60
    var expirationPickerView: UIDatePicker?

    var feedInfo: FeedInfo!
    var userInfo: UserInfo!
    var users: [UserInfo]!
    
    var toTourAll = false

    override func viewDidLoad() {
        super.viewDidLoad()

        if (feedInfo != nil) {
            nameLabel1.text = feedInfo.author
            nameLabel2.text = feedInfo.author
            credLabel.text = "Street Cred - \((feedInfo.userLiked)!)"
            summaryLabel.text = feedInfo.text
            addressLabel.text = " @ \((feedInfo.street)!)"
//            placeholderLabel.text = "Tell \((feedInfo.author)!) why you want a live tour"
            if (feedInfo.feedType == "event") {
                iconButton.setImage(#imageLiteral(resourceName: "events_icon"), for: .normal)
            } else {
                iconButton.setImage(#imageLiteral(resourceName: "alert_icon"), for: .normal)
            }
            
//            topMargin1.constant = topMargin1.constant - tourToHeightConstraint.constant
            topMargin2.constant = topMargin2.constant - tourToHeightConstraint.constant
            tourToHeightConstraint.constant = 0
            tourToView.isHidden = true
        } else if (userInfo != nil) {
            nameLabel1.text = userInfo.name
            nameLabel2.text = userInfo.name
            credLabel.text = "Street Cred - \((userInfo.liked)!)"
            summaryLabel.text = "\((userInfo.name)!) is available for a live street view"
            addressLabel.text = " @ \((userInfo.address)!)"
//            placeholderLabel.text = "Tell \((userInfo.name)!) why you want a live tour"
            
            tourToOnlyButton.setTitle("Send only to \((userInfo.name)!)", for: .normal)
            
            iconButton.setImage(#imageLiteral(resourceName: "adsfeeds_icon"), for: .normal)
        }

        expirationPickerView = UIDatePicker.init()
        expirationPickerView?.datePickerMode = .countDownTimer
        expirationPickerView?.addTarget(self, action: #selector(EventPostViewController.onChangedExpireTime), for: .valueChanged)
        
        expireTextField.delegate = self
        expireTextField.inputView = expirationPickerView
        
        self.onSendToButton(tourToOnlyButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UITextView Delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.inputView == expirationPickerView) {
            let deadlineTime = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                self.expirationPickerView?.countDownDuration = self.expiration
            }
        }
    }
    
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
    
    @objc func onChangedExpireTime() {
        expiration = (expirationPickerView?.countDownDuration)!
        let (h,m) = self.secondsToHoursMinutesSeconds(seconds: Int((expirationPickerView?.countDownDuration)!))
        
        expireHourLabel.text = "\(h)hr"
        expireTextField.text = "\(m)min"
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60)
    }
    
    @IBAction func onSendTourRequest(_ sender: Any) {
        if (reasonTextView.text.count == 0) {
            SVProgressHUD.showError(withStatus: "Please input the reason.")
            return;
        }
        
        SVProgressHUD.show(withStatus: "Sending a tour request...")
        if (feedInfo != nil) {
            FeedManager.shared.addTourRequest(feedInfo: self.feedInfo, reason: reasonTextView.text, expiration: expiration) { (success, result) in
                if (success == false) {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showError(withStatus: result)
                } else {
                    SVProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        } else {
            if (toTourAll == true) {
                FeedManager.shared.addTourUserRequest(users: self.users, reason: reasonTextView.text, expiration: expiration) { (success, result) in
                    if (success == false) {
                        SVProgressHUD.dismiss()
                        SVProgressHUD.showError(withStatus: result)
                    } else {
                        SVProgressHUD.dismiss()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } else {
                FeedManager.shared.addTourUserRequest(users: [self.userInfo], reason: reasonTextView.text, expiration: expiration) { (success, result) in
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
    }
    
    @IBAction func onSendToButton(_ sender: UIButton) {
        if (sender == tourToAllButton) {
            toTourAll = true
            tourToAllButton.setImage(#imageLiteral(resourceName: "checked_icon"), for: .normal)
            tourToOnlyButton.setImage(#imageLiteral(resourceName: "unchecked_icon"), for: .normal)
        } else {
            toTourAll = false
            tourToAllButton.setImage(#imageLiteral(resourceName: "unchecked_icon"), for: .normal)
            tourToOnlyButton.setImage(#imageLiteral(resourceName: "checked_icon"), for: .normal)
        }
    }
    
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
