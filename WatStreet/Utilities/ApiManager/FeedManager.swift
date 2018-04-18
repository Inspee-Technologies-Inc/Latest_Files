//
//  FeedManager.swift
//  WatStreet
//
//  Created by Eric on 12/18/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit
//import GeoFire

class FeedManager: NSObject {
    var feedRef: DatabaseReference!
    var followRef: DatabaseReference!
    var seeRef: DatabaseReference!
    var userRef: DatabaseReference!
    var tourRef: DatabaseReference!

    var addedObserver: UInt?
    var changedObserver: UInt?
    
    static let shared = FeedManager()
    
    override init() {
        super.init()
        
        feedRef = Database.database().reference().child("data").child("feeds")
        followRef = Database.database().reference().child("data").child("follows")
        seeRef = Database.database().reference().child("data").child("sees")
        userRef = Database.database().reference().child("data").child("users")
        tourRef = Database.database().reference().child("data").child("tours")
    }
    
    func setupEvent(
        added: @escaping (FeedInfo) -> (),
        changed: @escaping (FeedInfo) -> ()
        ) {
        
        if (addedObserver != nil) {
            feedRef.removeObserver(withHandle: addedObserver!)
            feedRef.removeObserver(withHandle: changedObserver!)
        }
        
        addedObserver = feedRef.queryOrdered(byChild: "created").queryStarting(atValue: Date().timeIntervalSince1970, childKey: "created").observe(.childAdded) { (snapshot) in
            if (snapshot.value is Dictionary<String, Any>) {
                added(FeedInfo().setJson(snapshot.value as! [String : Any], key: snapshot.key))
            }
        }
        
        changedObserver = feedRef.observe(.childChanged) { (snapshot) in
            if (snapshot.value is Dictionary<String, Any>) {
                changed(FeedInfo().setJson(snapshot.value as! [String : Any], key: snapshot.key))
            }
        }
    }
    
    func setupUserEvents(_ changed: @escaping (String, Int) -> ()) {
        userRef.observe(.childChanged) { (snapshot) in
            if (snapshot.value is Dictionary<String, Any>) {
                let userInfo = snapshot.value as! Dictionary<String, Any>
                changed(snapshot.key, (userInfo["liked"] == nil ? 0 : userInfo["liked"] as! Int))
            }
        }
    }
    
    func setupTourEvents(_ added: @escaping (TourRequestInfo) -> (), changed: @escaping (TourRequestInfo) -> ()) {
        tourRef.child((Auth.auth().currentUser?.uid)!).queryOrdered(byChild: "created").queryStarting(atValue: Date().timeIntervalSince1970, childKey: "created").observe(.childAdded) { (snapshot) in
            if (snapshot.value is Dictionary<String, Any>) {
                added(TourRequestInfo().setJson(snapshot.value as! [String : Any], key: snapshot.key))
            }
        }
        
        tourRef.child((Auth.auth().currentUser?.uid)!).observe(.childChanged) { (snapshot) in
            if (snapshot.value is Dictionary<String, Any>) {
                changed(TourRequestInfo().setJson(snapshot.value as! [String : Any], key: snapshot.key))
            }
        }
    }
    
    func setupLiveEvent(_ feedId: String!, changed: @escaping (Int) -> ()) {
        feedRef.child("live").observe(.childChanged) { (snapshot) in
            if (snapshot.value is Dictionary<String, Any> && snapshot.key == feedId) {
                let feedInfo = snapshot.value as! Dictionary<String, Any>
                changed((feedInfo["see"] == nil ? 0 : feedInfo["see"] as! Int))
            }
        }
    }
    
    func addEvent(_ summary: String!,
                  photoUrl: String!,
                  category: String!,
                  expiration: Double!,
                  location: CLLocation!,
                  feedType: String!
        ) {
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            var street = ""
            if (error == nil && (placemarks?.count)! > 0) {
                let pm = placemarks![0]
                street = (pm.thoroughfare == nil ? (pm.locality == nil ? "" : pm.locality)! : ("\((pm.subThoroughfare ?? "")!) \((pm.thoroughfare)!)"))
            }
            
            let param = [
                "text": summary,
                "photoUrl": photoUrl,
                "category": category,
                "feedType": feedType,
                "expiration": expiration,
                "userId": (Auth.auth().currentUser?.uid)!,
                "name": (Auth.auth().currentUser?.displayName)!,
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude,
                "geoHash": GFGeoHash.init(location: location.coordinate).geoHashValue,
                "street": street,
                "created": (Date().timeIntervalSince1970 + expiration),
                "liked": 0,
                "disliked": 0,
                "isSafe": false,
                ] as [String : Any]
            
            let childRef = self.feedRef.childByAutoId()
            childRef.setValue(param)
        }
    }
    
    func addLiveStream(_ location: CLLocation!, callback: @escaping (Bool, String) -> ()) {
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            var street = ""
            if (error == nil && (placemarks?.count)! > 0) {
                let pm = placemarks![0]
                street = (pm.thoroughfare == nil ? (pm.locality == nil ? "" : pm.locality) : pm.thoroughfare)!
            }
            
            let param = [
                "text": "",
                "photoUrl": "",
                "category": "",
                "feedType": "live",
                "expiration": 0,
                "userId": (Auth.auth().currentUser?.uid)!,
                "name": (Auth.auth().currentUser?.displayName)!,
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude,
                "geoHash": GFGeoHash.init(location: location.coordinate).geoHashValue,
                "street": street,
                "created": Date().timeIntervalSince1970,
                "liked": 0,
                "disliked": 0,
                "isSafe": false,
                "ended": true,
                ] as [String : Any]

            self.feedRef.child("live").child((Auth.auth().currentUser?.uid)!).setValue(param, withCompletionBlock: { (error, ref) in
                if (error == nil) {
                    callback (true, (Auth.auth().currentUser?.uid)!)
                } else {
                    callback (false, "")
                }
            })
        }
    }
    
    func clearLiveStream() {
        self.feedRef.child("live").child((Auth.auth().currentUser?.uid)!).removeValue()
    }
    
    func report(_ feed: FeedInfo!) {
        feed.reported = true
        feedRef.child(feed.feedType).child(feed.uid).setValue(feed.toJson())
    }
    
    func follow(_ feed: FeedInfo, like: Int!, callback: @escaping () -> ()) {
        followRef.child((Auth.auth().currentUser?.uid)!).child(feed.uid).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.value is NSNull) {
                self.followRef.child((Auth.auth().currentUser?.uid)!).child(feed.uid).setValue(like)
                self.userRef.child(feed.userId).observeSingleEvent(of: .value, with: { (user) in
                    if !(user.value is NSNull) {
                        var info = user.value as! [String: Any]
                        if (like == 1) {
                            info["liked"] = (info["liked"] == nil) ? 1 : (info["liked"] as! Int + 1)
                        } else {
                            info["disliked"] = (info["disliked"] == nil) ? 1 : (info["disliked"] as! Int + 1)
                        }
                        
                        self.userRef.child(feed.userId).setValue(info)
                    }
                })
                
                if (like == 1) {
                    feed.liked = feed.liked + 1
                } else {
                    feed.disliked = feed.disliked + 1
                }
                self.feedRef.child(feed.feedType).child(feed.uid).setValue(feed.toJson())
            }
            callback()
        }
    }
    
    func likeTour(_ tour: TourRequestInfo, like: Int!) {
        self.userRef.child(tour.userId).observeSingleEvent(of: .value, with: { (user) in
            if !(user.value is NSNull) {
                var info = user.value as! [String: Any]
                info["liked"] = (info["liked"] == nil) ? like : (info["liked"] as! Int + like)
                
                self.userRef.child(tour.userId).setValue(info)
            }
        })
        
        tourRef.child(tour.userId).child(tour.uid).child("liked").setValue(like)
        tourRef.child(tour.authorId).child(tour.uid).child("liked").setValue(like)
    }
    
    func see(_ feed: FeedInfo) {
        seeRef.child((Auth.auth().currentUser?.uid)!).child(feed.uid).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.value is NSNull) {
                self.seeRef.child((Auth.auth().currentUser?.uid)!).child(feed.uid).setValue(1)
                feed.see = feed.see + 1
                self.feedRef.child(feed.feedType).child(feed.uid).setValue(feed.toJson())
            }
        }
    }
    
    func closeStream(_ streamId: String!, callback: @escaping (Bool) -> ()) {
        feedRef.child("live").child(streamId).child("ended").setValue(true) { (error, ref) in
            callback(error == nil)
        }
    }
    
    func startStream(_ streamId: String!) {
        feedRef.child("live").child(streamId).child("ended").setValue(false)
    }

    func fetchFeed(_ location: CLLocationCoordinate2D, callback: @escaping ([FeedInfo]) -> ()) {
        let queries = GFGeoHashQuery.queries(forLocation: location, radius: 1000)
        for query in queries! {
            feedRef.queryOrdered(byChild: "geoHash")
                .queryStarting(atValue: (query as! GFGeoHashQuery).startValue, childKey: "geoHash")
                .queryEnding(atValue: (query as! GFGeoHashQuery).endValue, childKey: "geoHash")
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    if !(snapshot.value is NSNull) {
                        let array = snapshot.value as! [String: [String:Any]]
                        var feeds: [FeedInfo] = []
                        for (key, value) in array {
                            let feed = FeedInfo().setJson(value, key: key)
                            feeds.append(feed)
                        }
                        callback(feeds)
                    }
                })
        }
    }
    
    func fetchUsers(_ location: CLLocationCoordinate2D, callback: @escaping ([UserInfo]) -> ()) {
        let queries = GFGeoHashQuery.queries(forLocation: location, radius: 1000)
        for query in queries! {
            userRef.queryOrdered(byChild: "geoHash")
                .queryStarting(atValue: (query as! GFGeoHashQuery).startValue, childKey: "geoHash")
                .queryEnding(atValue: (query as! GFGeoHashQuery).endValue, childKey: "geoHash")
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    if !(snapshot.value is NSNull) {
                        let array = snapshot.value as! [String: [String:Any]]
                        var users: [UserInfo] = []
                        for (key, value) in array {
                            let user = UserInfo().setJson(value, key: key)
                            users.append(user)
                        }
                        callback(users)
                    }
                })
        }
    }
    
    func feedById(_ feedId: String!, callback: @escaping (FeedInfo) -> ()) {
        feedRef.child(feedId).observeSingleEvent(of: .value, with: {(snap) in
            callback(FeedInfo().setJson(snap.value as! [String : Any], key: feedId))
        })
    }
    
    func fetchTours(callback: @escaping ([TourRequestInfo]) -> ()) {
        tourRef.child((Auth.auth().currentUser?.uid)!)
            .observeSingleEvent(of: .value, with: { (snapshot) in
                if !(snapshot.value is NSNull) {
                    let array = snapshot.value as! [String: [String:Any]]
                    var tours: [TourRequestInfo] = []
                    for (key, value) in array {
                        let tour = TourRequestInfo().setJson(value, key: key)
                        tours.append(tour)
                    }
                    callback(tours)
                }
            })
    }
    
    // MARK: Tour Request
    func addTourRequest(feedInfo: FeedInfo!, reason: String!, callback: @escaping (Bool, String) -> ()) {
        let info = [
            "type": feedInfo.feedType,
            "reason": reason,
            "userId": (Auth.auth().currentUser?.uid)!,
            "userName": (Auth.auth().currentUser?.displayName)!,
            "feedId": feedInfo.uid,
            "authorId": feedInfo.userId,
            "authorName": feedInfo.author,
            "lat": feedInfo.lat,
            "lng": feedInfo.lng,
            "geoHash": GFGeoHash.init(location: CLLocationCoordinate2DMake(feedInfo.lat, feedInfo.lng)).geoHashValue,
            "street": feedInfo.street,
            "created": Date().timeIntervalSince1970,
            "status": "pending"
            ] as [String : Any]
        
        let childRef = tourRef.childByAutoId()
        let userId = (Auth.auth().currentUser?.uid)!
        let authorId = feedInfo.userId!
        
        tourRef.child(userId).child(childRef.key).setValue(info, withCompletionBlock: { (error, ref) in
            if (error == nil) {
                callback (true, "")
            } else {
                callback (false, (error?.localizedDescription)!)
            }
        })
        tourRef.child(authorId).child(childRef.key).setValue(info)
        
        // Send Push
        let toUserId = info["userId"] as! String
        let message = "\(info["userName"] as! String) has requested a \(feedInfo.feedType == "event" ? "live event or deal" : "safety alert") tour."
        ApiManager.sendPushNotification(toUserId: toUserId, message: message)
    }
    
    func addTourUserRequest(userInfo: UserInfo!, reason: String!, callback: @escaping (Bool, String) -> ()) {
        let info = [
            "type": "tour",
            "reason": reason,
            "userId": (Auth.auth().currentUser?.uid)!,
            "userName": (Auth.auth().currentUser?.displayName)!,
            "feedId": "",
            "authorId": userInfo.userId,
            "authorName": userInfo.name,
            "lat": userInfo.lat!,
            "lng": userInfo.lng!,
            "geoHash": GFGeoHash.init(location: CLLocationCoordinate2DMake(userInfo.lat!, userInfo.lng!)).geoHashValue,
            "street": userInfo.address,
            "created": Date().timeIntervalSince1970,
            "status": "pending"
            ] as [String : Any]
        
        let childRef = tourRef.childByAutoId()
        let userId = (Auth.auth().currentUser?.uid)!
        let authorId = userInfo.userId!
        
        tourRef.child(userId).child(childRef.key).setValue(info, withCompletionBlock: { (error, ref) in
            if (error == nil) {
                callback (true, "")
            } else {
                callback (false, (error?.localizedDescription)!)
            }
        })
        tourRef.child(authorId).child(childRef.key).setValue(info)
        
        // Send Push
        let toUserId = info["userId"] as! String
        let message = "\(info["userName"] as! String) sent you a tour request."
        ApiManager.sendPushNotification(toUserId: toUserId, message: message)
    }
    
    func rejectTour(_ tour: TourRequestInfo) {
        tour.status = "rejected"
        tourRef.child(tour.userId).child(tour.uid).child("status").setValue("rejected")
        tourRef.child(tour.authorId).child(tour.uid).child("status").setValue("rejected")
        
        // Send Push
        let toUserId = tour.userId
        let message = "Your tour request has been rejected. Try later."
        ApiManager.sendPushNotification(toUserId: toUserId, message: message)
    }
    
    func acceptTour(_ tour: TourRequestInfo, videoUrl: String) {
        tour.status = "accepted"
        tour.videoUrl = videoUrl
        tourRef.child(tour.userId).child(tour.uid).child("status").setValue("accepted")
        tourRef.child(tour.authorId).child(tour.uid).child("status").setValue("accepted")
        tourRef.child(tour.userId).child(tour.uid).child("videoUrl").setValue(videoUrl)
        tourRef.child(tour.authorId).child(tour.uid).child("videoUrl").setValue(videoUrl)
        
        // Send Push
        let toUserId = tour.userId
        let message = "Your tour request has been accepted."
        ApiManager.sendPushNotification(toUserId: toUserId, message: message)
    }
    
}
