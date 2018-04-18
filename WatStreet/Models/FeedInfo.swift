//
//  FeedInfo.swift
//  WatStreet
//
//  Created by Eric on 12/18/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class FeedInfo: NSObject {
    var uid: String!
    var userId: String!
    var text: String!
    var author: String!
    var liked: Int!
    var see: Int!
    var disliked: Int!
    var originJson: [String:Any]!
    var created: Double!
    var lat: Double!
    var lng: Double!
    var expiration: Double!
    var reported: Bool!
    var isSafe: Bool!
    var isBusiness: Bool!
    var userLiked: Int!
    var feedType: String!
    var photoUrl: String!
    var category: String!
    var street: String!
    var ended: Bool!

    func setJson(_ value: [String: Any]!, key: String!) -> FeedInfo {
        uid = key
        userId = value["userId"] as! String
        text = value["text"] as! String
        author = value["name"] as! String
        liked = value["liked"] as! Int
        disliked = value["disliked"] as! Int
        see = value["see"] == nil ? 0 : value["see"] as! Int
        created = value["created"] as! Double
        lat = value["lat"] as! Double
        lng = value["lng"] as! Double
        expiration = value["expiration"] == nil ? 0 : (value["expiration"] as! Double)
        reported = value["reported"] == nil ? false : (value["reported"] as! Bool)
        isSafe = value["isSafe"] == nil ? true : (value["isSafe"] as! Bool)
        isBusiness = value["isBusiness"] == nil ? false : (value["isBusiness"] as! Bool)
        feedType = value["feedType"] == nil ? "feed" : (value["feedType"] as! String)
        photoUrl = value["photoUrl"] == nil ? "" : (value["photoUrl"] as! String)
        category = value["category"] == nil ? "" : (value["category"] as! String)
        street = value["street"] == nil ? "" : (value["street"] as! String)
        ended = value["ended"] == nil ? false : (value["ended"] as! Bool)
        userLiked = 0
        
        Database.database().reference().child("data").child("users").child(self.userId).child("liked")
            .observeSingleEvent(of: .value) { (snapshot) in
                if (snapshot.value is Int && snapshot.key == "liked") {
                    self.userLiked = snapshot.value as! Int
                }
        }

        self.originJson = value
        return self
    }
    
    func toJson() -> [String:Any] {
        originJson["text"] = text
        originJson["liked"] = liked
        originJson["disliked"] = disliked
        originJson["reported"] = reported
        originJson["see"] = see
        return originJson
    }
    
    func getAgoString() -> String {
        let gap = Int(Date().timeIntervalSince1970 - created + self.expiration)
        
        if (gap < 60) {
            return "\(gap) SEC"
        } else if (gap < 3600) {
            return "\(gap / 60) MIN"
        } else if (gap < 3600 * 24) {
            return "\(gap / 3600) HOUR"
        } else if (gap < 3600 * 24 * 7) {
            return "\(gap / 3600 / 24) DAY"
        } else if (gap < 3600 * 24 * 30) {
            return "\(gap / 3600 / 24 / 7) WEEK"
        } else {
            return "\(gap / 3600 / 24 / 30) MONTH"
        }
    }
}
