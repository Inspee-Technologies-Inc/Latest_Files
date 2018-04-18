//
//  EvtSummaryTableViewCell.swift
//  WatStreet
//
//  Created by Eric on 1/15/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

class EvtSummaryTableViewCell: UITableViewCell, UITextViewDelegate {

    @IBOutlet weak var summaryTextView: UITextView!
    @IBOutlet weak var textLengthLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
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
        textLengthLabel.text = "\(String((summaryTextView.text?.count)!))/35"
    }

}
