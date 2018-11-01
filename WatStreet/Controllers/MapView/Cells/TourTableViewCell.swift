//
//  TourTableViewCell.swift
//  WatStreet
//
//  Created by star on 3/31/18.
//  Copyright © 2018 Eric Park. All rights reserved.
//

import UIKit
import FirebaseAuth

class TourTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectIcon: UILabel!
    @IBOutlet weak var seeButton: UIButton!
    @IBOutlet weak var buttonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var seeButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rejectButtonWidthConstraint: NSLayoutConstraint!
    
    var orgButtonWidth: CGFloat!
    var orgSeeWidth: CGFloat!
    var orgStatusWidth: CGFloat!

    override func awakeFromNib() {
        super.awakeFromNib()

        acceptButton.clipsToBounds = true
        acceptButton.layer.cornerRadius = 15

        rejectButton.clipsToBounds = true
        rejectButton.layer.cornerRadius = 15
        
        orgButtonWidth = buttonWidthConstraint.constant
        orgSeeWidth = seeButtonWidthConstraint.constant
        orgStatusWidth = rejectButtonWidthConstraint.constant
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setTourInfo(_ tour: TourRequestInfo, indexPath: IndexPath) {
        timeLabel.text = tour.getAgoString()
        let type = tour.type == "event" ? "event or deal tour" : (tour.type == "tour" ? "live street view" : "safety tour")
        
        var bodyText = ""
        var nameText = ""
        if (tour.authorId == Auth.auth().currentUser?.uid) {
            bodyText = "\((tour.userName)!) has requested a \(type)."
            nameText = tour.userName
            
            if (tour.status == "pending") {
                buttonWidthConstraint.constant = orgButtonWidth
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = 0
            } else if (tour.status == "accepted") {
                rejectIcon.text = "COMPLETED"
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = orgStatusWidth
            } else if (tour.status == "cancelled") {
                rejectIcon.text = "CANCELLED"
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = orgStatusWidth
            } else if (tour.status == "expired") {
                rejectIcon.text = "EXPIRED"
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = orgStatusWidth
            } else {
                rejectIcon.text = "REJECTED"
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = orgStatusWidth
            }
        } else {
            nameText = "Your"
            if (tour.status == "pending") {
                bodyText = "Your \(type) is still pending"
                rejectIcon.text = "PENDING"
                
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = orgStatusWidth
            } else if (tour.status == "accepted") {
                bodyText = "Your \(type) has been accepted."
                
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = orgSeeWidth
                rejectButtonWidthConstraint.constant = 0
            } else if (tour.status == "expired") {
                bodyText = "Your \(type) was expired. Try later."
                rejectIcon.text = "EXPIRED"
                
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = orgStatusWidth
            } else {
                bodyText = "Your \(type) was rejected. Try later."
                rejectIcon.text = "REJECTED"
                
                buttonWidthConstraint.constant = 0
                seeButtonWidthConstraint.constant = 0
                rejectButtonWidthConstraint.constant = orgStatusWidth
            }
        }
        
        let attributeStr = NSMutableAttributedString.init(string: bodyText)
        attributeStr.addAttribute(NSAttributedStringKey.foregroundColor, value: rejectIcon.textColor, range: NSRange(location: 0, length: nameText.count))
        contentLabel.attributedText = attributeStr
        
        seeButton.tag = indexPath.row
        acceptButton.tag = indexPath.row
        rejectButton.tag = indexPath.row
    }

}
