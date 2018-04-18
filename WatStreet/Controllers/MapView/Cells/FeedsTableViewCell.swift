//
//  FeedsTableViewCell.swift
//  WatStreet
//
//  Created by Developer on 11/30/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit

class FeedsTableViewCell: UITableViewCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var stredCredLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    @IBOutlet weak var feedsTypeImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var requestTourButton: UIButton!
    @IBOutlet weak var detailButton: UIButton!
    
    var feedInfo: FeedInfo!
    var userInfo: UserInfo!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(FeedsTableViewCell.onTapCred)))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func onTapCred() {
        userNameLabel.text = "Street Cred - \(InputValidator.getCount(feedInfo == nil ? userInfo.liked : feedInfo.userLiked))"
        userNameLabel.font = UIFont.init(name: userNameLabel.font.fontName, size: 11.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.userNameLabel.text = self.feedInfo == nil ? self.userInfo.name.capitalized : self.feedInfo.author.capitalized
            self.userNameLabel.font = UIFont.init(name: self.userNameLabel.font.fontName, size: 14.0)
        }
    }

}
