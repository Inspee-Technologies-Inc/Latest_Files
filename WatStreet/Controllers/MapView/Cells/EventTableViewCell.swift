//
//  FeedsTableViewCell.swift
//  WatStreet
//
//  Created by Developer on 11/30/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(FeedsTableViewCell.onTapCred)))
        
        expTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(EventTableViewCell.onExpTimer), userInfo: nil, repeats: true)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @objc func onTapCred() {
        if (feedInfo.isBusiness) {
            userNameLabel.text = "Business Cred - \(InputValidator.getCount(feedInfo.userLiked))"
        } else {
            userNameLabel.text = "Street Cred - \(InputValidator.getCount(feedInfo.userLiked))"
        }
        
        userNameLabel.font = UIFont.init(name: userNameLabel.font.fontName, size: 11.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.userNameLabel.text = self.feedInfo.author.capitalized
            self.userNameLabel.font = UIFont.init(name: self.userNameLabel.font.fontName, size: 14.0)
        }
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

