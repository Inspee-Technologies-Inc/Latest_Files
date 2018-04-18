//
//  PasswordResetViewController.swift
//  WatStreet
//
//  Created by Eric on 12/17/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import SVProgressHUD
import SkyFloatingLabelTextField

class PasswordResetViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var passwordTextField: BlackDotImageTextField!
    @IBOutlet weak var createPwdButton: UIButton!
    
    var userInfo: UserInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Initialization
    
    func initUI() {
        passwordTextField.delegate = self
        
        passwordTextField.backgroundColor = UIColor.clear
        passwordTextField.tintColor = ColorUtils.overcastBlueColor // the color of the blinking cursor
        passwordTextField.textColor = ColorUtils.darkGreyColor
        passwordTextField.lineColor = ColorUtils.lightGreyColor
        passwordTextField.selectedTitleColor = ColorUtils.overcastBlueColor
        passwordTextField.selectedLineColor = ColorUtils.overcastBlueColor
        
        passwordTextField.iconType = .image
        passwordTextField.iconImage = #imageLiteral(resourceName: "password")
        passwordTextField.addBlackDot()
        
        passwordTextField.lineHeight = 1.0 // bottom line height in points
        passwordTextField.selectedLineHeight = 1.0
        passwordTextField.text = ""
        
        createPwdButton.clipsToBounds = true
        createPwdButton.layer.cornerRadius = 30
        createPwdButton.layer.borderWidth = 0.5
        createPwdButton.layer.borderColor = UIColor.init(white: 0.2, alpha: 0.2).cgColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: UI Events
    
    @IBAction func onCreatePassword(_ sender: Any) {
        if (passwordTextField.text == "") {
            SVProgressHUD.showError(withStatus: "Please enter your password.")
            return
        }
        
        SVProgressHUD.show(withStatus: "Resetting Password...")
        self.userInfo!.password = passwordTextField.text
        
        ApiManager.resetPassword(user: self.userInfo!, success: {
            SVProgressHUD.dismiss()
            SVProgressHUD.showInfo(withStatus: "Password was successfully reset.")
            self.navigationController?.popToRootViewController(animated: true)
        }) { (error) in
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: error)
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}
