//
//  TourDetailViewController.swift
//  WatStreet
//
//  Created by star on 3/31/18.
//  Copyright © 2018 Eric Park. All rights reserved.
//

import UIKit

class TourDetailViewController: UIViewController {
    @IBOutlet weak var nameLabel1: UILabel!
    @IBOutlet weak var credLabel: UILabel!
    @IBOutlet weak var nameLabel2: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var iconButton: UIButton!
    @IBOutlet weak var reasonTextView: UITextView!
    
    var tourInfo: TourRequestInfo!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nameLabel1.text = tourInfo.authorName
        self.nameLabel2.text = tourInfo.authorName
        self.addressLabel.text = " @ \((tourInfo.street)!)"
        self.reasonTextView.text = self.tourInfo.reason

        if (tourInfo.feedId == "") {
            iconButton.setImage(#imageLiteral(resourceName: "adsfeeds_icon"), for: .normal)
            ApiManager.shared.userById(tourInfo.authorId, callback: { (user) in
                self.credLabel.text = "Street Cred - \((user.liked)!)"
                self.summaryLabel.text = "\((user.name)!) is available for a live street view"
            })
        } else {
            if (tourInfo.type == "event") {
                iconButton.setImage(#imageLiteral(resourceName: "events_icon"), for: .normal)
            } else {
                iconButton.setImage(#imageLiteral(resourceName: "alert_icon"), for: .normal)
            }
            FeedManager.shared.feedById(tourInfo.feedId) { (feedInfo) in
                self.credLabel.text = "Street Cred - \((feedInfo.userLiked)!)"
                self.summaryLabel.text = feedInfo.text
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func onClose(_ sender: Any) {
        (self.parent as! MainViewController).onTapTransparentView()
    }
}
