//
//  InputValidator.swift
//  TimezoneApp
//
//  Created by Benjamin on 11/29/17.
//  Copyright © 2017 Benjamin Mayette. All rights reserved.
//

import UIKit

class InputValidator: NSObject {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailCheck = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailCheck.evaluate(with: email)
    }
    
    static func isValidBusinessEmail(_ email: String, businessName: String!) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailCheck = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        if (!emailCheck.evaluate(with: email)) {
            return false
        }
        
        let keywords = businessName.lowercased().components(separatedBy: " ")
        let domain = InputValidator.getDomain(email).lowercased()
        
        for keyword in keywords {
            if (domain.range(of: keyword) != nil) {
                return true
            }
        }
        
        return false
    }
    
    static func getDomain(_ email: String!) -> String {
        var v = email.components(separatedBy: "@").last?.components(separatedBy: ".")
        v?.removeLast()
        
        return (v!.last)!
    }
    
    static func getCount(_ count: Int!) -> String {
        if (count < 1000) {
            return "\(String(count))"
        } else {
            return "\(String(count / 1000))k"
        }
    }

}
