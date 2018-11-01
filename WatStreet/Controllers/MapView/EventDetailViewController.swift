//
//  EventDetailViewController.swift
//  WatStreet
//
//  Created by star on 3/31/18.
//  Copyright © 2018 Eric Park. All rights reserved.
//

import UIKit
import SDWebImage
import SVProgressHUD
import FirebaseAuth

class EventDetailViewController: UIViewController {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var stredCredLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dissLikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var reportbutton: UIButton!
    @IBOutlet weak var feedlikeLabel: UILabel!
    @IBOutlet weak var dislikeLabel: UILabel!
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var expireLabel: UILabel!
    @IBOutlet weak var categoryHeightConstraint: NSLayoutConstraint!
    
    var expTimer: Timer?
    var feedInfo: FeedInfo!

    override func viewDidLoad() {
        super.viewDidLoad()

        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(FeedsTableViewCell.onTapCred)))
        categoryLabel.text = feedInfo.category
        messageLabel.text = feedInfo.text
        userNameLabel.text = feedInfo.author
        stredCredLabel.text = " @ \((feedInfo.street)!)"
        
        feedlikeLabel.text = "\((feedInfo.liked)!)"
        dislikeLabel.text = "\((feedInfo.disliked)!)"
        if (feedInfo.reported) {
            reportbutton.tintColor = UIColor.red
            reportbutton.isUserInteractionEnabled = false
        }
        photoImageView.sd_setImage(with: URL.init(string: feedInfo.photoUrl)) { (image, error, cacheType, url) in
            if (error == nil) {
                self.photoImageView.image = image
                self.photoImageView.contentMode = .scaleAspectFill
            }
        }

        expTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(EventTableViewCell.onExpTimer), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI Events
    
    @IBAction func onClose(_ sender: Any) {
        (self.parent as! MainViewController).onTapTransparentView()
    }
    
    @objc func onTapCred() {
        userNameLabel.text = "Street Cred - \(InputValidator.getCount(feedInfo.userLiked))"
        userNameLabel.font = UIFont.init(name: userNameLabel.font.fontName, size: 11.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.userNameLabel.text = self.feedInfo.author.capitalized
            self.userNameLabel.font = UIFont.init(name: self.userNameLabel.font.fontName, size: 14.0)
        }
    }
    
    @IBAction func onLikeFeed(_ sender: UIButton) {
        if (feedInfo.userId == Auth.auth().currentUser?.uid) {
            SVProgressHUD.showError(withStatus: "You cannot like your feed.")
            return
        }
        FeedManager.shared.follow(feedInfo, like: 1) {
            self.feedlikeLabel.text = "\((self.feedInfo.userLiked)!)"
        }
    }
    
    @IBAction func onDislikeFeed(_ sender: UIButton) {
        if (feedInfo.userId == Auth.auth().currentUser?.uid) {
            SVProgressHUD.showError(withStatus: "You cannot dislike your feed.")
            return
        }
        FeedManager.shared.follow(feedInfo, like: 1) {
            self.dislikeLabel.text = "\((self.feedInfo.disliked)!)"
        }
    }
    
    @IBAction func onReportFeed(_ sender: UIButton) {
        let alert = UIAlertController.init(title: "Would you like to report this content?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (action) in
            FeedManager.shared.report(self.feedInfo)
            self.reportbutton.tintColor = UIColor.red
            
            SVProgressHUD.showError(withStatus: "This post has been reported and is being reviewed.")
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func onExpTimer() {
        if (feedInfo != nil) {
            if (feedInfo.feedType == "event") {
                let (h, m, s) = self.secondsToHoursMinutesSeconds(created: feedInfo.created)
                expireLabel.text = String.init(format: "%02d:%02d:%02d", h, m, s)
            } else {
                let (h, m, s) = self.secondsToHoursMinutesSeconds(created: feedInfo.created, expire: feedInfo.expiration)
                expireLabel.text = String.init(format: "%02d:%02d:%02d", h, m, s)
            }
        }
    }
    
    func secondsToHoursMinutesSeconds (created : Double!) -> (Int, Int, Int) {
        let seconds = Int(created - Date().timeIntervalSince1970)
        return (seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
    
    func secondsToHoursMinutesSeconds (created : Double!, expire: Double!) -> (Int, Int, Int) {
        let seconds = Int(Date().timeIntervalSince1970 - (created - expire))
        return (seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

}
