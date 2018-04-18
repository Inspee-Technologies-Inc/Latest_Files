//
//  EvtExpirationTableViewCell.swift
//  WatStreet
//
//  Created by Eric on 1/15/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

class EvtExpirationTableViewCell: UITableViewCell {

    @IBOutlet weak var expirationDummyInputField: UITextField!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
