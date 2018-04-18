//
//  ApiManager.swift
//  WatStreet
//


import UIKit
import MapKit
import Alamofire
import FirebaseAuth
import FirebaseDatabase

class ApiManager: NSObject {
    static let shared = ApiManager()
    
    static let BASE_URL = "http://18.188.88.233:1337"
    static let CONNECTION_FAILED_MSG = "Could not connect to server."
    
    var ref: DatabaseReference!
    
    override init() {
        ref = Database.database().reference()
    }
    
    func fetchAllMapObjects(completion: @escaping(_ success: Bool,_ mapObjects:[[String:Any]]?) -> Void) {
        ref.child("data").child("mapobjects").observeSingleEvent(of: .value, with: { (snapshot) in
            if let mapObjectsDictionary = snapshot.value as? [String:Any] {
                let mapObjectsArray = Array(mapObjectsDictionary.values) as! [[String:Any]]
                completion(true, mapObjectsArray)
            } else {
                completion(false, nil)
            }
        }) { (error) in
            completion(false, nil)
        }
    }
    
    func fetchTotalCreeds(userName:String, completion: @escaping(_ success: Bool,_ totalCreeds: String) -> Void) {
        var totalPoints = 0
        fetchAllMapObjects { (success, mapObjects) in
            if success == true, let objectsArray = mapObjects  {
                for mapObject in objectsArray {
                    if let feedsDictionary = mapObject["feeds"] as? [String:Any] {
                        let feedsArray = Array(feedsDictionary.values) as! [[String:Any]]
                        for feed in feedsArray {
                            let feedUsername = feed["username"] as! String
                            if feedUsername == userName, let feedCredit = feed["credits"] as? String, let credits = Int(feedCredit) {
                                totalPoints += credits
                            }
                        }
                    }
                }
                completion(true, String(totalPoints))
            } else {
                completion(false, String(totalPoints))
            }
        }
    }
    
    func fetchAllFeedsForMapObject(mapObjectId: String, completion: @escaping(_ success: Bool,_ feeds:[[String:Any]]?) -> Void) {
        ref.child("data").child("mapobjects").child(mapObjectId).child("feeds").observeSingleEvent(of: .value, with: { (snapshot) in
            if let feedObjectsDictionary = snapshot.value as? [String:Any] {
                let feedObjectsArray = Array(feedObjectsDictionary.values) as! [[String:Any]]
                completion(true, feedObjectsArray)
            } else {
                completion(false, nil)
            }
        }) { (error) in
            completion(false, nil)
        }
    }
    
    func addNewMapObject(mapObject:[String:Any], completion: @escaping(_ id: String?,_ success: Bool) -> Void) {
        let key = ref.child("data").child("mapobjects").childByAutoId().key
        var mapData = mapObject
        mapData["id"] = key
        ref.child("data").child("mapobjects").child(key).setValue(mapData) { (error, ref) in
            if error == nil {
                completion(key, true)
            } else {
                completion(nil, false)
            }
        }
    }
    
    func addNewFeedToMapObject(mapId:String ,feed:[String:String], completion: @escaping(_ id:String?, _ success: Bool) -> Void) {
        let mapObjectId = mapId
        let key = ref.child("data").child("mapobjects").child(mapObjectId).child("feeds").childByAutoId().key
        var feedData = feed
        feedData["id"] = key
        ref.child("data").child("mapobjects").child(mapObjectId).child("feeds").child(key).setValue(feedData) { (error, ref) in
            if error == nil {
                completion(key,true)
            } else {
                completion(nil,false)
            }
        }
    }
    
    func updateCreed(mapObjId: String, feed: [String:Any], point: Int, completion: @escaping(_ countcredits:String?,_ success:Bool) -> Void) {
        let feedID = feed["id"] as! String
        var newFeed = feed
        var creditsCount = 0
        if let credits = feed["credits"] as? String, let count = Int(credits) {
            creditsCount = count+point
        }
        newFeed["credits"] = String(creditsCount)
        ref.child("data").child("mapobjects").child(mapObjId).child("feeds").child(feedID).setValue(newFeed) { (error, ref) in
            if error == nil {
                completion(String(creditsCount), true)
            } else {
                completion(nil, false)
            }
        }
    }
    
    func updateCountUsersInMapObject(mapObject: [String:Any], point: Int, completion: @escaping(_ countusers: String?,_ success: Bool) -> Void) {
        var mapData = mapObject
        let mapid = mapData["id"] as! String
        var countusers = 0
        if let users = mapData["countusers"] as? String, let count = Int(users) {
            countusers = count+point
            if countusers <= 0 {
                countusers = 0
            }
        }
        ref.child("data").child("mapobjects").child(mapid).child("feeds").observeSingleEvent(of: .value, with: { (snapshot) in
            if let feedObjectsDictionary = snapshot.value as? [String:Any] {
                mapData["feeds"] = feedObjectsDictionary
                mapData["countusers"] = String(countusers)
                self.ref.child("data").child("mapobjects").child(mapid).setValue(mapData) { (error, ref) in
                    if error == nil {
                        completion(String(countusers),true)
                    } else {
                        completion(nil,false)
                    }
                }
            } else {
                mapData["countusers"] = String(countusers)
                self.ref.child("data").child("mapobjects").child(mapid).setValue(mapData) { (error, ref) in
                    if error == nil {
                        completion(String(countusers),true)
                    } else {
                        completion(nil,false)
                    }
                }
            }
        }) { (error) in
            print(error)
        }
        
    }
    
    func removeFeed(mapObjectId:String, feedID:String, completion: @escaping(_ success: Bool) -> Void) {
        ref.child("data").child("mapobjects").child(mapObjectId).child("feeds").child(feedID).removeValue { (error, ref) in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    static func login(
        email: String!,
        password: String!,
        success: @escaping () -> (),
        error: @escaping (_ msg: String?) -> ()
        ) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
            if (err == nil) {
                ApiManager.loadUser(user: user, success: success)
            } else {
                error(err?.localizedDescription)
            }
        }
    }
    
    static func loadUser(
        user: User!,
        success: @escaping () -> ()) {
        Database.database().reference().child("data")
            .child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.value == nil || snapshot.value is NSNull) {
            } else {
                let info = snapshot.value as! [String:Any]
                User.currentUser = UserInfo().setJson(info, key: snapshot.key)
                success()
            }
        })
    }
    
    // MARK: Customized API Calls
    static func register(
        email: String!,
        success: @escaping () -> (),
        error: @escaping (_ msg: String?) -> ()
        ) {
        
        let url = "\(BASE_URL)/user/sendEmailVerifyCode"
        
        let params = [
            "email": email
            ] as Parameters?
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.error == nil {
                if response.response?.statusCode == 200 {
                    success ()
                } else {
                    error((response.value as! Dictionary <String, String>)["error"])
                }
            } else {
                error(CONNECTION_FAILED_MSG)
            }
        }
    }
    
    static func verify(
        user: UserInfo!,
        code: String!,
        success: @escaping () -> (),
        error: @escaping (_ msg: String?) -> ()
        ) {
        
        let url = "\(BASE_URL)/user/verifyCode"
        
        var params = [
            "email": user.email!,
            "password": user.password!,
            "address": "",
            "isBusinessAccount": false,
            "name": user.name!,
            "code": code
            ] as Parameters?
        
        if (user.lat != nil && user.lng != nil) {
            params!["lat"] = user.lat
            params!["lng"] = user.lng
        } else {
            params!["lat"] = 0
            params!["lng"] = 0
        }
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.error == nil {
                if response.response?.statusCode == 200 {
                    success ()
                } else {
                    error((response.value as! Dictionary <String, String>)["error"])
                }
            } else {
                error(CONNECTION_FAILED_MSG)
            }
        }
    }
    
    static func forgotPassword(
        email: String!,
        success: @escaping () -> (),
        error: @escaping (_ msg: String?) -> ()
        ) {
        
        let url = "\(BASE_URL)/user/sendForgotPasswordReq"
        
        let params = [
            "email": email
            ] as Parameters?
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.error == nil {
                if response.response?.statusCode == 200 {
                    success ()
                } else {
                    error((response.value as! Dictionary <String, String>)["error"])
                }
            } else {
                error(CONNECTION_FAILED_MSG)
            }
        }
    }
    
    static func verifyForgot(
        email: String!,
        code: String!,
        success: @escaping (_ token: String?) -> (),
        error: @escaping (_ msg: String?) -> ()
        ) {
        
        let url = "\(BASE_URL)/user/verifyForgotCode"
        
        let params = [
            "email": email,
            "code": code
            ] as Parameters?
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.error == nil {
                if response.response?.statusCode == 200 {
                    success((response.value as! Dictionary <String, String>)["token"])
                } else {
                    error((response.value as! Dictionary <String, String>)["error"])
                }
            } else {
                error(CONNECTION_FAILED_MSG)
            }
        }
    }
    
    static func resetPassword(
        user: UserInfo!,
        success: @escaping () -> (),
        error: @escaping (_ msg: String?) -> ()
        ) {
        
        let url = "\(BASE_URL)/user/resetPassword"
        
        let params = [
            "email": user.email ?? "",
            "password": user.password ?? "",
            "token": user.token ?? ""
            ] as Parameters?
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.error == nil {
                if response.response?.statusCode == 200 {
                    success()
                } else {
                    error((response.value as! Dictionary <String, String>)["error"])
                }
            } else {
                error(CONNECTION_FAILED_MSG)
            }
        }
    }
    
    static func sendPushNotification(
        toUserId: String!,
        message: String!
        ) {
        
        let url = "\(BASE_URL)/user/sendPush"
        
        let params = [
            "toUserId": toUserId,
            "message": message
            ] as Parameters?
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
        }
    }
    
    // User Flag Settings
    
    func setUserStatus(_ status: Bool) {
        ref.child("data").child("users")
            .child((Auth.auth().currentUser?.uid)!).child("isActive").setValue(status)
    }
    
    func setUserLocation(_ location: CLLocation) {
        print("---- Location Updated ----")
        ref.child("data").child("users")
            .child((Auth.auth().currentUser?.uid)!)
            .child("lat").setValue(location.coordinate.latitude)
        
        ref.child("data").child("users")
            .child((Auth.auth().currentUser?.uid)!)
            .child("lng").setValue(location.coordinate.longitude)
        
        ref.child("data").child("users")
            .child((Auth.auth().currentUser?.uid)!)
            .child("geoHash").setValue(GFGeoHash.init(location: location.coordinate).geoHashValue)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            var street = ""
            if (error == nil && (placemarks?.count)! > 0) {
                let pm = placemarks![0]
                street = (pm.thoroughfare == nil ? (pm.locality == nil ? "" : pm.locality)! : ("\((pm.subThoroughfare ?? "")!) \((pm.thoroughfare)!)"))
            }
        
            self.ref.child("data").child("users")
                .child((Auth.auth().currentUser?.uid)!)
                .child("address").setValue(street)
        }
    }
    
    func setDeviceToken() {
        let token = (UIApplication.shared.delegate as! AppDelegate).deviceToken
        if (token != nil) {
            self.ref.child("data").child("users")
                .child((Auth.auth().currentUser?.uid)!)
                .child("deviceToken").setValue(token)
        }
    }
    
    func userById(_ userId: String!, callback: @escaping (UserInfo) -> ()) {
        self.ref.child("data").child("users")
            .child(userId).observeSingleEvent(of: .value, with: {(snap) in
            callback(UserInfo().setJson(snap.value as! [String : Any], key: userId))
        })
    }
}
