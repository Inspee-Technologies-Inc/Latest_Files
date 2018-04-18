//
//  SkyTextField+BlackDot.swift
//  WatStreet
//
//  Created by star on 2/11/18.
//  Copyright © 2018 Eric Park. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class BlackDotImageTextField: SkyFloatingLabelTextFieldWithIcon {
    
    var dotView: UIView!
    
    func addBlackDot() {
        dotView = UIView.init()
        
        dotView.backgroundColor = self.lineColor
        dotView.clipsToBounds = true
        dotView.layer.cornerRadius = 2.5
        dotView.frame = CGRect(x: 0, y: self.frame.size.height - 3, width: 5, height: 5)
        
        self.addSubview(dotView)
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        
        if (dotView != nil) {
            dotView.backgroundColor = self.isEditing ? self.selectedLineColor : self.lineColor
        }
        
        return result
    }
    
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        
        if (dotView != nil) {
            dotView.backgroundColor = self.isEditing ? self.selectedLineColor : self.lineColor
        }
        
        return result
    }
}


