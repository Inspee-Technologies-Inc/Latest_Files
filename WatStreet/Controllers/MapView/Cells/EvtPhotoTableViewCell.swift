//
//  EvtPhotoTableViewCell.swift
//  WatStreet
//
//  Created by Eric on 1/15/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

class EvtPhotoTableViewCell: UITableViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if (animated) {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = highlighted ? 0.7 : 1
            })
        } else {
            self.alpha = highlighted ? 0.7 : 1
        }
    }

}
