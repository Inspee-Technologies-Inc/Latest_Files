//
//  EventPostViewController.swift
//  WatStreet
//
//  Created by Eric on 1/15/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class EventPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var wizardTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var categoryPickerView: UIPickerView!
    var photoImageView: UIImageView?
    var categoryInputField: UITextField?
    var expirationPickerView: UIDatePicker?
    
    var expirationCell: EvtExpirationTableViewCell!
    var summaryCell: EvtSummaryTableViewCell!
    
    var photoImage: UIImage?
    var expiration: TimeInterval = 23 * 3600 + 59 * 60

    var isLiveDealEvent: Bool!
    var curLocation: CLLocation!
    var categories: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (self.isLiveDealEvent == true) {
            titleLabel.text = "LIVE DEALS AND EVENTS"
            categories = ["Music", "Food & Drinks", "Arts & Craft", "Educational", "Sports & Fitness", "Holidays", "Other"]
        } else {
            titleLabel.text = "LIVE SAFETY ALERTS"
            categories = ["Arrest", "Arson", "Assault", "Death", "Large Crowd", "Lost Item", "Public Ashaming", "Self-Inflicting", "Shooting", "Suspicious Acts", "Suspicious Sound", "Theft", "Vandalism"]
        }
        
        categoryPickerView = UIPickerView.init()
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        
        expirationPickerView = UIDatePicker.init()
        expirationPickerView?.datePickerMode = .countDownTimer
        expirationPickerView?.addTarget(self, action: #selector(EventPostViewController.onChangedExpireTime), for: .valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UI Events
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func onTakePhoto() {
        let alertView = UIAlertController.init(title: "Please Choose Source for Photo.", message: nil, preferredStyle: .actionSheet)
        
        alertView.addAction(UIAlertAction.init(title: "Photo Library", style: .default, handler: { (action) in
            let picker = UIImagePickerController.init()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }))
        alertView.addAction(UIAlertAction.init(title: "Camera", style: .default, handler: { (action) in
            let picker = UIImagePickerController.init()
            picker.sourceType = .camera
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }))
        alertView.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alertView, animated: true, completion: nil)
    }
    
    @objc func onChangedExpireTime() {
        expiration = (expirationPickerView?.countDownDuration)!
        let (h,m) = self.secondsToHoursMinutesSeconds(seconds: Int((expirationPickerView?.countDownDuration)!))
        
        expirationCell.hourLabel.text = "\(h)hr"
        expirationCell.minLabel.text = "\(m)min"
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60)
    }
    
    @IBAction func onPostEvent(_ sender: Any) {
        if (photoImage == nil) {
            SVProgressHUD.showError(withStatus: "Please select photo.")
            return;
        } else if (!isLiveDealEvent && categoryInputField?.text == "") {
            SVProgressHUD.showError(withStatus: "Please select category.")
            return;
        } else if (summaryCell.summaryTextView.text == "") {
            SVProgressHUD.showError(withStatus: "Please describe your live event.")
            return;
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let imageData:Data = UIImageJPEGRepresentation(photoImage!, 1)! as Data
        
        // Create a reference to the file you want to upload
        let riversRef = storageRef.child("photos/\(Date.timeIntervalSinceReferenceDate).jpg")
        
        // Upload the file to the path "images/rivers.jpg"
        SVProgressHUD.show(withStatus: "Uploading photo...")
        riversRef.putData(imageData, metadata: nil) { (metadata, error) in
            SVProgressHUD.dismiss()
            if (error != nil) {
                SVProgressHUD.showError(withStatus: "Could not upload photo.")
                return
            }
            
            let photoUrl = metadata?.downloadURL()?.absoluteString
            let category = self.categoryInputField?.text
            let summary = self.summaryCell.summaryTextView.text
            
            FeedManager.init().addEvent(summary,
                                        photoUrl: photoUrl,
                                        category: category,
                                        expiration: self.expiration,
                                        location: self.curLocation,
                                        feedType: self.isLiveDealEvent ? "event" : "alert")
            for controller in (self.navigationController?.viewControllers)! {
                if (controller is MainViewController) {
                    self.navigationController?.popToViewController(controller, animated: true)
                    return
                }
            }
        }
    }
    
    // MARK: TextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.inputView == expirationPickerView) {
            let deadlineTime = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
//                var dateComp : DateComponents = DateComponents()
//                dateComp.hour = 23
//                dateComp.minute = 59
//                dateComp.timeZone = TimeZone.current
//                let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
//                let date = calendar.date(from: dateComp)
                
                self.expirationPickerView?.countDownDuration = self.expiration
            }
        }
    }
    
    // MARK: ImagePickerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        photoImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        photoImageView?.contentMode = .scaleAspectFill
        photoImageView?.clipsToBounds = true
        photoImageView?.image = photoImage
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: CategoryPickerView Delegate & DataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryInputField?.text = categories[row]
    }
    
    // MARK: UITableView DataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell") as! EvtPhotoTableViewCell
            
            cell.photoImageView.isUserInteractionEnabled = true
            if (photoImageView == nil) {
                photoImageView = cell.photoImageView
            }
            
            return cell
        } else if (indexPath.row == 1) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") as! EvtCategoryTableViewCell
            if (categoryInputField == nil) {
                cell.categoryTextField.inputView = categoryPickerView
                categoryInputField = cell.categoryTextField
            }
            return cell
        } else if (indexPath.row == 2) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCell") as! EvtSummaryTableViewCell
            if (isLiveDealEvent == true) {
                cell.titleLabel.text = "DESCRIBE YOUR LIVE DEALS AND EVENTS"
            } else {
                cell.titleLabel.text = "DESCRIBE YOUR LIVE SAFETY ALERT"
            }
            summaryCell = cell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExpireCell") as! EvtExpirationTableViewCell
            cell.expirationDummyInputField.delegate = self
            cell.expirationDummyInputField.inputView = expirationPickerView
            
            if (isLiveDealEvent == true) {
                cell.titleLabel.text = "EXPIRATION TIME"
            } else {
                cell.titleLabel.text = "ALERT TIME"
            }
            
            expirationCell = cell
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return 202
        } else if (indexPath.row == 1 && !self.isLiveDealEvent) {
            return 78
        } else if ((indexPath.row == 1 && self.isLiveDealEvent) || (indexPath.row == 2 && !self.isLiveDealEvent)) {
            return 92
        } else {
            return 75
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.row == 0) {
            self.onTakePhoto()
        } else if (indexPath.row == 1 && !self.isLiveDealEvent) {
            categoryInputField?.becomeFirstResponder()
        } else if ((indexPath.row == 1 && self.isLiveDealEvent) || (indexPath.row == 2 && !self.isLiveDealEvent)) {
            
        } else {
            
        }
    }
}
