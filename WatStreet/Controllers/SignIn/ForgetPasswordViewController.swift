//
//  ForgetPasswordViewController.swift
//  WatStreet
//
//  Created by Eric on 12/17/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import SVProgressHUD
import SkyFloatingLabelTextField


class ForgetPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: BlackDotImageTextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as! VerifyCodeViewController).isFromForgot = true
        
        let user = UserInfo.init()
        
        user.email = self.emailTextField.text;
        
        (segue.destination as! VerifyCodeViewController).userInfo = user
    }
    
    // MARK: Initialization
    
    func initUI() {
        emailTextField.delegate = self

        emailTextField.backgroundColor = UIColor.clear
        emailTextField.tintColor = ColorUtils.overcastBlueColor // the color of the blinking cursor
        emailTextField.textColor = ColorUtils.darkGreyColor
        emailTextField.lineColor = ColorUtils.darkGreyColor
        emailTextField.selectedTitleColor = ColorUtils.overcastBlueColor
        emailTextField.selectedLineColor = ColorUtils.overcastBlueColor
        
        emailTextField.lineHeight = 1.0 // bottom line height in points
        emailTextField.selectedLineHeight = 1.0
        emailTextField.text = ""
        emailTextField.addBlackDot()
        emailTextField.iconType = .image
        emailTextField.iconImage = #imageLiteral(resourceName: "email")
        
        sendCodeButton.clipsToBounds = true
        sendCodeButton.layer.cornerRadius = 30
        sendCodeButton.layer.borderWidth = 0.5
        sendCodeButton.layer.borderColor = UIColor.init(white: 0.2, alpha: 0.2).cgColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: UI Events

    @IBAction func onSendVerifyCode(_ sender: Any) {
        if (emailTextField.text == "") {
            SVProgressHUD.showError(withStatus: "Please enter your business email.")
            return
        }
        
        SVProgressHUD.show(withStatus: "Sending Verification Code...")
        ApiManager.forgotPassword(email: emailTextField.text, success: {
            SVProgressHUD.dismiss()
            self.performSegue(withIdentifier: "VerifyView", sender: nil)
        }) { (error) in
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: error)
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
