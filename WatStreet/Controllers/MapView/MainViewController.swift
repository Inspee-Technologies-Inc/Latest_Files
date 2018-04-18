//
//  MainViewController.swift
//  WatStreet
//
//  Created by Eric on 12/18/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import MapKit
import GooglePlaces
import SVProgressHUD
import SkyFloatingLabelTextField
import IQKeyboardManagerSwift

import FirebaseAuth
import FirebaseDatabase

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var postButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var trackModeSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stredCredLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var streetInputView: UIView!
    @IBOutlet weak var streetNameField: UITextField!
    
    @IBOutlet var tabButtons: [UIButton]!
    @IBOutlet weak var postExtraButton: UIButton!

    @IBOutlet weak var feedContainerView: UIView!

    @IBOutlet weak var nofeedLabel: UILabel!
    @IBOutlet weak var nofeedView: UIView!
    
    @IBOutlet weak var tourTabView: UIView!
    @IBOutlet weak var requestsTabButton: UIButton!
    @IBOutlet weak var myToursTabButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeView: UIView!
    
    let feedManager = FeedManager.init()

    var locationManager: CLLocationManager!
    var curLocation: CLLocation?
    var curPrecisLocation: CLLocation?
    var feedType = "feed"
    var curOverlay: MKCircle?
    var pointAnnotation: MKPointAnnotation?
    
    var feedTableView: FeedsTableViewController!
    var videoViewController: StreamPlayerViewController!
    
    // Street Search
    var placesClient: GMSPlacesClient!
    var placesArray: [GMSAutocompletePrediction] = []
    var placesTableView: UITableView!
    var lat: Double?
    var lng: Double?
    
    // Popup
    var transparentView: UIView!
    var popupController: UIViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ApiManager.shared.setUserStatus(true)

        self.initUI()
        self.initMap()
        self.setupMeLiked()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        feedManager.clearLiveStream()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is FeedsTableViewController) {
            feedTableView = segue.destination as! FeedsTableViewController
        } else if (segue.destination is StreamPlayerViewController) {
            videoViewController = segue.destination as! StreamPlayerViewController
        } else if (segue.destination is FirstViewController) {
            (segue.destination as! FirstViewController).curLocation = self.curPrecisLocation
        } else if (segue.destination is LiveStreamViewController) {
            (segue.destination as! LiveStreamViewController).streamKey = (sender as! String)
        } else if (segue.destination is RequestTourViewController) {
            if (sender is FeedInfo) {
                (segue.destination as! RequestTourViewController).feedInfo = (sender as! FeedInfo)
            } else {
                (segue.destination as! RequestTourViewController).userInfo = (sender as! UserInfo)
            }
        }
    }
    
    // MARK: UI Initialization
    
    func initUI() {
        streetInputView.isHidden = true
        
        titleLabel.text = Auth.auth().currentUser?.displayName?.capitalized
        
        for button in tabButtons {
            button.addTarget(self, action: #selector(MainViewController.onTabButtonClicked(_:)), for: .touchUpInside)
        }
        
        self.onTabButtonClicked(tabButtons[0])
        postExtraButton.isHidden = true
        
        placesClient = GMSPlacesClient.shared()
        streetNameField.delegate = self
        placesTableView = UITableView.init()
        placesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        placesTableView.delegate = self
        placesTableView.dataSource = self
        placesTableView.isHidden = false
        
        self.view.addSubview(placesTableView)
        
        badgeLabel.clipsToBounds = true
        badgeLabel.layer.cornerRadius = 10
    }
    
    func initMap() {
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            self.onTrackmodeChanged(trackModeSwitch)
        } else {
            SVProgressHUD.showError(withStatus: "Please enable location service to use track mode.")
            trackModeSwitch.isOn = false
            trackModeSwitch.isUserInteractionEnabled = false
            self.onTrackmodeChanged(trackModeSwitch)
        }
    }
    
    func setupMeLiked() {
        self.stredCredLabel.text = "Street Cred - \(InputValidator.getCount((User.currentUser?.liked)!))"
        
        Database.database().reference().child("data").child("users").child((Auth.auth().currentUser?.uid)!)
            .observe(.childChanged) { (snapshot) in
            if (snapshot.value is Int && snapshot.key == "liked") {
                self.stredCredLabel.text = "Street Cred - \(InputValidator.getCount(snapshot.value as! Int))"
            }
        }
    }
    
    // MARK: Location Manager
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        curPrecisLocation = locations.last

        if (curLocation == nil || (curLocation?.distance(from: curPrecisLocation!))! > 100.0) {
            ApiManager.shared.setUserLocation(curPrecisLocation!)
        }

        if (curLocation != nil && (curLocation?.distance(from: curPrecisLocation!))! < 1000.0) {
            return
        }

        self.updateLocation(location: curPrecisLocation)
    }
    
    func updateLocation(location: CLLocation!) {
        curLocation = location
        
        let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
        
        self.mapView.setRegion(region, animated: true)
        
        if (curOverlay != nil) {
            mapView.removeOverlays([curOverlay!])
        }
        curOverlay = MKCircle.init(center: location.coordinate, radius: 1000)
        mapView.addOverlays([curOverlay!])
        
        if (pointAnnotation != nil) {
            mapView.removeAnnotation(pointAnnotation!)
        }

        if (!trackModeSwitch.isOn) {
            pointAnnotation = MKPointAnnotation.init()
            pointAnnotation?.coordinate = location.coordinate
            mapView.addAnnotation(pointAnnotation!)
        }
        
        feedTableView.updateLocation(feedType, location: location.coordinate)
        refreshPostButtonStatus()
    }
    
    func refreshBadgeLabel(_ tours:[TourRequestInfo]) {
        var pendingCount = 0
        for tour in tours {
            if (tour.authorId == Auth.auth().currentUser?.uid && tour.status == "pending") {
                pendingCount = pendingCount + 1
            } else if (tour.userId == Auth.auth().currentUser?.uid && tour.status == "accepted" && tour.liked == 0) {
                pendingCount = pendingCount + 1
            }
        }
        
        badgeLabel.text = "\(pendingCount)"
        badgeView.isHidden = pendingCount == 0
        UIApplication.shared.applicationIconBadgeNumber = pendingCount
    }
    
    // MARK: MapView Delegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleView = MKCircleRenderer.init(overlay: overlay)
        circleView.strokeColor = UIColor.blue
        circleView.lineWidth = 1.5
        circleView.fillColor = UIColor.blue.withAlphaComponent(0.3)
        return circleView
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView?.canShowCallout = true
        }
        else {
            anView?.annotation = annotation
        }
        
        anView?.image = UIImage(named:"man_pin")
        
        return anView
    }
    
    // MARK: UI Events
    
    @IBAction func onBack(_ sender: Any) {
        let alertController = UIAlertController.init(title: "Do you like to log out?", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (action) in
            do {
                if (Auth.auth().currentUser != nil) {
                    ApiManager.shared.setUserStatus(false)
                }

                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            
            self.navigationController?.popToRootViewController(animated: true)
        }))
        
        alertController.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func onPostEvent(_ sender: Any) {
        if (curPrecisLocation == nil) {
            return
        }
        
        self.performSegue(withIdentifier: "PostEventView", sender: nil)
    }
    
    @IBAction func onTrackmodeChanged(_ sender: Any) {
        streetInputView.isHidden = trackModeSwitch.isOn
        
        mapView.showsUserLocation = trackModeSwitch.isOn
        mapView.isUserInteractionEnabled = !trackModeSwitch.isOn
        if (!trackModeSwitch.isOn && curOverlay != nil) {
            mapView.removeOverlays([curOverlay!])
        }
        
        if (locationManager != nil) {
            curLocation = nil
            if (trackModeSwitch.isOn) {
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingLocation()
            }
        }
        
        refreshPostButtonStatus()
    }
    
    @IBAction func onGoToStreet(_ sender: Any) {
        if (lat != nil && lng != nil) {
            self.updateLocation(location: CLLocation.init(latitude: lat!, longitude: lng!))
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string.count == 0) {
            return true
        } else if (string.count + (textField.text?.count)! <= 35) {
            return true
        } else {
            return false
        }
    }
    
    @IBAction func streetChanged(_ sender: Any) {
        placesTableView.isHidden = false
        placesTableView.frame = CGRect(x: 0, y: 157, width: self.view.frame.size.width, height: (self.view.frame.size.height - 157))
        
        self.view.bringSubview(toFront: placesTableView)
        
        let filter = GMSAutocompleteFilter()
        filter.type = .address;
        placesClient.autocompleteQuery(streetNameField.text!, bounds: nil, filter: filter) { (places, error) in
            if error == nil {
                self.placesArray = places!
                self.placesTableView.reloadData()
            }
        }
    }
    
    @objc func onTabButtonClicked(_ sender:UIButton) {
        self.view.endEditing(true)

        for button in tabButtons {
            button.tintColor = UIColor.lightGray
        }
        sender.tintColor = UIColor.blue
        
        // Process based on the selected tab bar item
        if (sender == tabButtons[0]) {
            postExtraButton.isHidden = false
            feedType = "feed"
        } else if (sender == tabButtons[1]) {
            postExtraButton.isHidden = true
            feedType = "tour"
        }
        
        refreshPostButtonStatus()

        if (curLocation != nil) {
            feedTableView.updateLocation(feedType, location: (curLocation?.coordinate)!)
        }
    }
    
    @IBAction func onTourTabClicked(_ sender: UIButton) {
        if (sender == requestsTabButton) {
            requestsTabButton.backgroundColor = UIColor.lightGray
            myToursTabButton.backgroundColor = postExtraButton.backgroundColor
            videoView.isHidden = true
            
            feedTableView.isTourMine = false
        } else {
            requestsTabButton.backgroundColor = postExtraButton.backgroundColor
            myToursTabButton.backgroundColor = UIColor.lightGray
            videoView.isHidden = true
            
            feedTableView.isTourMine = true
        }
        
        if (curLocation != nil) {
            feedTableView.updateLocation(feedType, location: (curLocation?.coordinate)!)
        }
    }
    
    
    func refreshPostButtonStatus() {
        if (trackModeSwitch.isOn == false || curLocation == nil) {
            postButtonHeightConstraint.constant = 0
            postExtraButton.isHidden = true
        } else {
            postButtonHeightConstraint.constant = 55
            postExtraButton.isHidden = false
        }
        
        if (feedType == "feed") {
            tourTabView.isHidden = true
            videoView.isHidden = true
        } else {
            tourTabView.isHidden = false
            postButtonHeightConstraint.constant = 55
            videoView.isHidden = true
        }
    }
    
    // MARK: Popover View
    
    func presentPopoverView(_ controller: UIViewController) {
        if (transparentView == nil) {
            transparentView = UIView.init(frame: self.view.bounds)
            transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            transparentView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(MainViewController.onTapTransparentView)))
        }
        self.popupController = controller
        self.addChildViewController(controller)
        self.view.addSubview(transparentView)
        self.view.addSubview(controller.view)
        transparentView.alpha = 0
        controller.view.center = CGPoint(x: self.view.bounds.size.width / 2, y: self.view.bounds.size.height)
        
        UIView.animate(withDuration: 0.3) {
            self.transparentView.alpha = 1
            self.popupController.view.center = self.view.center
        }
    }
    
    @objc func onTapTransparentView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.transparentView.alpha = 0
            self.popupController.view.center = CGPoint(x: self.view.bounds.size.width / 2, y: self.view.bounds.size.height)
        }) { (completed) in
            self.popupController.view.removeFromSuperview()
            self.popupController.removeFromParentViewController()
            self.transparentView.removeFromSuperview()
        }
    }
    
    func onViewTourVideo(_ tour: TourRequestInfo) {
        videoViewController.setTours([tour])
        videoView.isHidden = false
    }
    
    // MARK: UITableView Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        let place = placesArray[indexPath.row]
        cell?.textLabel?.attributedText = place.attributedFullText
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let place = placesArray[indexPath.row]
        streetNameField.text = place.attributedFullText.string
        placesTableView.isHidden = true
        
        placesClient.lookUpPlaceID(place.placeID!) { (place, error) in
            if (error == nil) {
                self.lat = place?.coordinate.latitude
                self.lng = place?.coordinate.longitude
            }
        }
        
        self.view.endEditing(true)
    }
}
