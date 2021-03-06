//
//  UserInfo.swift
//  WatStreet
//
//  Created by Eric on 12/17/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import FirebaseAuth

class UserInfo: NSObject {
    var userId: String!
    var email: String!
    var password: String?
    var name: String!
    var address: String!
    var token: String?
    var liked: Int!
    var lat: Double?
    var lng: Double?
    var isActive: Bool!
    var blockedUsers: [String]!
    
    func setJson(_ value: [String: Any]!, key: String!) -> UserInfo {
        userId = key
        
        name = value["name"] as! String
        email = value["email"] as! String
        liked = value["liked"] == nil ? 0 : value["liked"] as! Int
        lat = value["lat"] as? Double
        lng = value["lng"] as? Double
        address = value["address"] == nil ? "" : value["address"] as! String
        isActive = value["isActive"] == nil ? false : value["isActive"] as! Bool
        blockedUsers = value["blockedUsers"] == nil ? [] : value["blockedUsers"] as! [String]

        return self
    }
    
    func blockUser(_ userId: String) {
        if (blockedUsers.index(of: userId) == nil) {
            blockedUsers.append(userId)
        }
    }
    
    func isBlocked() -> Bool {
        return User.currentUser?.blockedUsers.index(of: userId) != nil
    }
}
