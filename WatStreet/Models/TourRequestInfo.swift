//
//  TourRequestInfo.swift
//  WatStreet
//
//  Created by star on 3/29/18.
//  Copyright © 2018 Eric Park. All rights reserved.
//

import UIKit

class TourRequestInfo: NSObject {
    var uid: String!
    var type: String!
    var userId: String!
    var userName: String!
    var feedId: String!
    var street: String!
    var authorId: String!
    var authorName: String!
    var reason: String!
    var lat: Double!
    var lng: Double!
    var status: String!
    var videoUrl: String!
    var created: Double!
    var liked: Int!
    var expiration: TimeInterval!
    var userIds: [String]!

    func setJson(_ value: [String: Any]!, key: String!) -> TourRequestInfo {
        uid = key
        
        type = value["type"] as! String
        userId = value["userId"] as! String
        userName = value["userName"] as! String
        feedId = value["feedId"] as! String
        street = value["street"] as! String
        authorId = value["authorId"] as! String
        authorName = value["authorName"] as! String
        reason = value["reason"] as! String
        lat = value["lat"] as! Double
        lng = value["lng"] as! Double
        status = value["status"] as! String
        created = value["created"] as! Double
        videoUrl = value["videoUrl"] == nil ? "" : value["videoUrl"] as! String
        liked = value["liked"] == nil ? 0 : value["liked"] as! Int
        expiration = value["expiration"] == nil ? 0 : value["expiration"] as! TimeInterval
        userIds = value["userIds"] == nil ? [] : value["userIds"] as! [String]
        
        let fornow = Date().timeIntervalSince1970
        if (status == "pending" && created + expiration < fornow) {
            status = "expired"
        }
        
        return self
    }
    
    func getAgoString() -> String {
        let gap = Int(Date().timeIntervalSince1970 - created)
        
        if (gap < 60) {
            return "\(gap) Secs Ago"
        } else if (gap < 3600) {
            return "\(gap / 60) Mins Ago"
        } else if (gap < 3600 * 24) {
            return "\(gap / 3600) Hrs Ago"
        } else if (gap < 3600 * 24 * 7) {
            return "\(gap / 3600 / 24) Days Ago"
        } else if (gap < 3600 * 24 * 30) {
            return "\(gap / 3600 / 24 / 7) Weeks Ago"
        } else {
            return "\(gap / 3600 / 24 / 30) Months ago"
        }
    }
}
