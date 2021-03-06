//
//  FeedsTableViewController.swift
//  WatStreet
//
//  Created by Eric on 12/18/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import SVProgressHUD
import MapKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImage
import MobileCoreServices

class FeedsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var feedManager: FeedManager!
    var feeds: [FeedInfo]! = []
    var tours: [TourRequestInfo]! = []
    var tours_all: [TourRequestInfo]! = []
    var users: [UserInfo]! = []
    let safeIcon = UIImage.init(named: "lock_icon")
    let personIcon = UIImage.init(named: "adsfeeds_icon")
    
    var feedType = "feed"
    var isTourMine = false
    var filterOption = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        
        feedManager = FeedManager.init()
        
        feedManager.setupUserEvents { (userId, liked) in
            for feed in self.feeds {
                if (feed.userId == userId) {
                    feed.userLiked = liked
                }
            }
            
            self.tableView.reloadData()
            self.showNoFeedLabel()
        }
        
        feedManager.fetchTours(callback: { (tours) in
            self.tours.removeAll()
            self.tours_all.removeAll()
            self.tours_all.append(contentsOf: tours)
            
            for tour in tours {
                if (self.isTourMine) {
                    if (tour.authorId == Auth.auth().currentUser?.uid) {
                        self.tours.append(tour)
                    }
                } else {
                    if (tour.userId == Auth.auth().currentUser?.uid) {
                        self.tours.append(tour)
                    }
                }
            }
            
            self.sortout()
            
            if (self.feedType == "tour") {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.showNoFeedLabel()
                    self.scrollToLast()
                }
            } else {
                (self.parent as! MainViewController).refreshBadgeLabel(self.tours_all)
            }
        })
        
        feedManager.setupTourEvents({ (tour) in
            print(" -------- Tour Added ---------")
            if ((self.parent as! MainViewController).curLocation != nil && ((self.parent as! MainViewController).curLocation?.distance(from: CLLocation.init(latitude: tour.lat, longitude: tour.lng)))! > 1000) {
                return
            }
            
            for item in self.tours {
                if (item.uid == tour.uid) {
                    return
                }
            }
            
            if (self.isTourMine) {
                if (tour.authorId == Auth.auth().currentUser?.uid) {
                    self.tours.append(tour)
                }
            } else {
                if (tour.userId == Auth.auth().currentUser?.uid) {
                    self.tours.append(tour)
                }
            }
            self.tours_all.append(tour)
            
            if (self.feedType == "tour") {
                self.tableView.reloadData()
                self.scrollToLast()
                self.showNoFeedLabel()
            } else {
                (self.parent as! MainViewController).refreshBadgeLabel(self.tours_all)
            }
        }) { (tour) in
            for item in self.tours_all {
                if (item.uid == tour.uid) {
                    item.status = tour.status
                    item.videoUrl = tour.videoUrl
                    
                    if (self.feedType == "tour") {
                        self.tableView.reloadData()
                    } else {
                        (self.parent as! MainViewController).refreshBadgeLabel(self.tours_all)
                    }
                    
                    return
                }
            }
        }
    }
    
    func scrollToLast() {
        let rows = self.tableView(self.tableView, numberOfRowsInSection: 0)
        if (rows > 0) {
            self.tableView.scrollToRow(at: IndexPath(row: (rows - 1), section: 0), at: .bottom, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is StreamPlayerViewController) {
            (segue.destination as! StreamPlayerViewController).feedInfo = sender as! FeedInfo
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.showNoFeedLabel()
    }
    
    func setupEvents() {
        feedManager.setupEvent(added: { (feed) in
            print(" -------- Added ---------")
            if (((self.parent as! MainViewController).curLocation?.distance(from: CLLocation.init(latitude: feed.lat, longitude: feed.lng)))! > 1000) {
                return
            }
            
            if (feed.reported == true) {
                return
            }
            
            for item in self.feeds {
                if (item.uid == feed.uid) {
                    return
                }
            }
            
            self.feeds.append(feed)
            self.tableView.reloadData()
            self.scrollToLast()
            self.showNoFeedLabel()
        }) { (feed) in
            print(" -------- Changed ---------")
            for item in self.feeds {
                if (item.uid == feed.uid) {
                    print(item.setJson(feed.originJson, key: feed.uid))
                    
                    if (item.feedType == "live" && item.ended) {
                        self.feeds.remove(at: self.feeds.index(of: item)!)
                    }
                    
                    self.tableView.reloadData()
                    self.showNoFeedLabel()
                    return
                }
            }
            
            if (feed.feedType == "live" && feed.ended == false) {
                self.feeds.append(feed)
                self.tableView.reloadData()
                self.showNoFeedLabel()
            }
        }
    }
    
    func showNoFeedLabel() {
        let noFeedLabel = (self.parent as! MainViewController).nofeedLabel
        let noFeedObjLabel = (self.parent as! MainViewController).nofeedObjLabel
        let noFeedView = (self.parent as! MainViewController).nofeedView
        if (feedType == "feed") {
            noFeedLabel?.text = filterOption == 2 ? "Available Guides" : "Live Tours"
            
            if (filterOption == 0) {
                noFeedView?.isHidden = (feeds.count + users.count > 0)
            } else if (filterOption == 1) {
                noFeedView?.isHidden = (feeds.count > 0)
            } else {
                noFeedView?.isHidden = (users.count > 0)
            }
            
            noFeedObjLabel?.text = "There is no"
        } else {
            noFeedLabel?.text = "Tours"
            noFeedView?.isHidden = (tours.count > 0)
        }
        
        noFeedView?.frame = (self.view.superview?.frame)!
        self.tableView.isHidden = !(noFeedView?.isHidden)!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateLocation(_ feedType: String!, location: CLLocationCoordinate2D?) {
        
        self.feedType = feedType
        if (feedType == "feed") {
            self.setupEvents()
            feeds.removeAll()
            users.removeAll()
            self.tableView.reloadData()
        } else {
            self.tours.removeAll()
            self.tableView.reloadData()
        }
        
        self.showNoFeedLabel()

        if (feedType == "feed") {
            feedManager.fetchFeed(location!) { (feeds) in
                print(" -------- Fetched ---------")
                self.feeds.removeAll()
                for item in feeds {
                    if (item.reported == true) {
                        continue
                    }
                    self.feeds.append(item)
                }
                self.sortout()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.showNoFeedLabel()
                    self.scrollToLast()
                }
            }
            
            feedManager.fetchUsers(location!, callback: { (users) in
                self.users.removeAll()
                for user in users {
                    if (user.userId != Auth.auth().currentUser?.uid && user.isActive && !user.isBlocked()) {
                        self.users.append(user)
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.showNoFeedLabel()
                }
            })
        } else {
            self.tours.removeAll()
            
            for tour in self.tours_all {
                if (self.isTourMine) {
                    if (tour.authorId == Auth.auth().currentUser?.uid) {
                        self.tours.append(tour)
                    }
                } else {
                    if (tour.userId == Auth.auth().currentUser?.uid) {
                        self.tours.append(tour)
                    }
                }
            }
            
            self.sortout()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.showNoFeedLabel()
                self.scrollToLast()
            }
        }
        
    }
    
    func sortout() {
        feeds.sort { (first, second) -> Bool in
            return first.created < second.created
        }
        
        tours.sort { (first, second) -> Bool in
            return first.created < second.created
        }
    }
    
    // MARK: UI Events
    
    @IBAction func onViewDetail(_ sender: UIButton) {
        self.performSegue(withIdentifier: "StreamView", sender: feeds[sender.tag])
    }
    
    @IBAction func onAccceptTour(_ sender: UIButton) {
        let tourView = self.storyboard?.instantiateViewController(withIdentifier: "TourDetailView") as! TourDetailViewController
        tourView.tourInfo = tours[sender.tag]
        tourView.view.frame = CGRect(x: 0, y: 0, width: (UIScreen.main.bounds.size.width - 60), height: 350)
        tourView.myTag = sender.tag
        tourView.superCtrler = self
        
        (self.parent as! MainViewController).presentPopoverView(tourView)
    }
    
    @IBAction func onRejectTour(_ sender: UIButton) {
        let tour = tours[sender.tag]
        FeedManager.shared.rejectTour(tour)
        self.tableView.reloadData()
        
        (self.parent as! MainViewController).refreshBadgeLabel(self.tours_all)
    }
    
    @IBAction func onSeeTour(_ sender: UIButton) {
        let tour = tours[sender.tag]
        (self.parent as! MainViewController).onViewTourVideo(tour)
    }
    
    @IBAction func onRequestTour(_ sender: UIButton) {
        if ((User.currentUser?.liked)! < 2) {
            SVProgressHUD.showError(withStatus: "You have to have a street cred to request a tour.")
            return
        }
        
        if ((filterOption == 0 && sender.tag < feeds.count) || filterOption == 1) {
            let feed = feeds[sender.tag]
            if (feed.userId == Auth.auth().currentUser?.uid) {
                SVProgressHUD.showError(withStatus: "You cannot ask a tour request to yourself.")
                return
            }
            
            (self.parent as! MainViewController).performSegue(withIdentifier: "RequestView", sender: feed)
        } else {
            let user = users[sender.tag - (filterOption == 0 ? feeds.count : 0)]
            (self.parent as! MainViewController).performSegue(withIdentifier: "RequestView", sender: user)
        }
    }
    
    @IBAction func onReportFeed(_ sender: UIButton) {
        if ((filterOption == 0 && sender.tag < feeds.count) || filterOption == 1) {
            let feed = feeds[sender.tag]
            if (feed.userId == Auth.auth().currentUser?.uid) {
                SVProgressHUD.showError(withStatus: "You cannot report your feed.")
                return
            }

            let alert = UIAlertController.init(title: "Would you like to report this content?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (action) in
                FeedManager.shared.report(feed)
                self.feeds.remove(at: sender.tag)
                self.tableView.reloadData()
                
                SVProgressHUD.showError(withStatus: "This post has been reported and is being reviewed.")
            }))
            alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let user = users[sender.tag - (filterOption == 0 ? feeds.count : 0)]
            
            let alert = UIAlertController.init(title: "Would you like to block this user?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (action) in
                FeedManager.shared.reportUser(user)
                self.users.remove(at: (self.filterOption == 0 ? sender.tag - self.feeds.count : sender.tag))
                self.tableView.reloadData()
                
                SVProgressHUD.showError(withStatus: "This user has been blocked.")
            }))
            alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Take Video Part
    
    func onTakeVideo(_ tourIndex: Int) {
//        let alertView = UIAlertController.init(title: "Please Choose Source for Photo.", message: nil, preferredStyle: .actionSheet)
//
//        alertView.addAction(UIAlertAction.init(title: "Photo Library", style: .default, handler: { (action) in
//            let picker = UIImagePickerController.init()
//            picker.sourceType = .photoLibrary
//            picker.mediaTypes = [kUTTypeMovie as String]
//            picker.videoMaximumDuration = 40
//            picker.delegate = self
//            picker.view.tag = tourIndex
//            self.present(picker, animated: true, completion: nil)
//        }))
//        alertView.addAction(UIAlertAction.init(title: "Camera", style: .default, handler: { (action) in
            let picker = UIImagePickerController.init()
            picker.sourceType = .camera
            picker.mediaTypes = [kUTTypeMovie as String]
            picker.delegate = self
            picker.videoMaximumDuration = 40
            picker.view.tag = tourIndex
            self.present(picker, animated: true, completion: nil)
//        }))
//        alertView.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
//
//        self.present(alertView, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let tour = tours[picker.view.tag]
        let videoURL = info[UIImagePickerControllerMediaURL] as! URL
        
        // Upload Video
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let riversRef = storageRef.child("videos/\(Date.timeIntervalSinceReferenceDate).mov")
        let meta = StorageMetadata.init()
        meta.contentType = "video/mov"
        
        SVProgressHUD.show(withStatus: "Uploading video...")
        riversRef.putFile(from: videoURL, metadata: meta) { (metadata, error) in
            SVProgressHUD.dismiss()
            if (error != nil) {
                SVProgressHUD.showError(withStatus: "Could not upload video.")
                return
            }
            
            let vUploadedUrl = metadata?.downloadURL()?.absoluteString
            FeedManager.shared.acceptTour(tour, videoUrl: vUploadedUrl!)
            self.tableView.reloadData()
            (self.parent as! MainViewController).refreshBadgeLabel(self.tours_all)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.feedType == "feed") {
            if (filterOption == 0) {
                return feeds.count + users.count
            } else if (filterOption == 1) {
                return feeds.count
            } else {
                return users.count
            }
        } else {
            return tours.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.feedType == "feed") {
            return 102
        } else {
            return 78
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (self.feedType == "feed") {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell") as! FeedsTableViewCell
            cell.reportButton.tag = indexPath.row
            
            if ( (filterOption == 0 || filterOption == 1) && indexPath.row < feeds.count) {
                let feed = feeds[indexPath.row]
                cell.feedInfo = feed
                cell.userInfo = nil
                
                cell.userNameLabel.text = feed.author.capitalized
                cell.messageLabel.text = feed.text
                cell.stredCredLabel.text = " @ \((feed.street)!)"
                cell.timeAgoLabel.text = feed.getAgoString()
                cell.feedsTypeImageView.image = feed.feedType == "event" ? #imageLiteral(resourceName: "events_icon") : #imageLiteral(resourceName: "alert_icon")
                cell.detailButton.isHidden = false
                cell.detailButton.tag = indexPath.row
                cell.requestTourButton.tag = indexPath.row
                cell.detailWidthConstraint.constant = 30
                cell.requestWidthConstraint.constant = 0
            } else {
                let user = filterOption == 1 ? users[indexPath.row - feeds.count] : users[indexPath.row]
                cell.userInfo = user
                cell.feedInfo = nil

                cell.userNameLabel.text = user.name
                cell.stredCredLabel.text = " @ Nearby Streets" //\((user.address)!)"
                cell.timeAgoLabel.text = "NOW"
                cell.messageLabel.text = "\((user.name)!) is available for a quick tour"
                cell.detailButton.isHidden = true
                cell.requestTourButton.tag = indexPath.row
                cell.feedsTypeImageView.image = #imageLiteral(resourceName: "adsfeeds_icon")
                cell.detailWidthConstraint.constant = 0
                cell.requestWidthConstraint.constant = 30
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TourCell") as! TourTableViewCell
            cell.setTourInfo(tours[indexPath.row], indexPath: indexPath)
            
            if (indexPath.row % 2 == 0) {
                cell.backgroundColor = ColorUtils.cellEvenColor
            } else {
                cell.backgroundColor = ColorUtils.cellOddColor
            }
            
            return cell
        }
    }

}
