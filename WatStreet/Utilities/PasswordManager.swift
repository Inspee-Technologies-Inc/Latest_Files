//
//  PasswordManager.swift
//  WatStreet
//
//  Created by Eric on 1/27/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import Foundation

class PasswordManager: NSObject {
    static func saveLogin(_ email: String!, password: String!)  {
        UserDefaults.standard.setValue(email, forKey: "email")
        UserDefaults.standard.setValue(password, forKey: "password")
    }
    
    static func savedLogin() -> (Bool, String, String) {
        let email = UserDefaults.standard.value(forKey: "email") as? String
        let password = UserDefaults.standard.value(forKey: "password") as? String
        
        if (email == nil) {
            return (false, "", "")
        } else {
            return (true, email!, password!)
        }
    }
    
    static func removeLogin() {
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "password")
    }
}
