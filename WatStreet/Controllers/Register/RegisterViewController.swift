
//
//  RegisterViewController.swift
//  WatStreet
//
//  Created by Eric on 12/17/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit

import FirebaseAuth
import FirebaseDatabase
import SVProgressHUD
import SkyFloatingLabelTextField

class RegisterViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: BlackDotTextField!
    @IBOutlet weak var emailTextField: BlackDotImageTextField!
    @IBOutlet weak var passwordTextField: BlackDotImageTextField!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    
    var termsAgreed: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
        termsAgreed = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is VerifyCodeViewController) {
            let user = UserInfo.init()
            user.name = self.nameTextField.text
            user.email = self.emailTextField.text
            user.password = self.passwordTextField.text
            
            (segue.destination as! VerifyCodeViewController).userInfo = user
            (segue.destination as! VerifyCodeViewController).isFromForgot = false
        }
    }
    
    // MARK: Initialization
    
    func initUI() {
        let textFields = [nameTextField, emailTextField, passwordTextField] as [SkyFloatingLabelTextField]

        for field in textFields {
            field.backgroundColor = UIColor.clear
            field.tintColor = ColorUtils.overcastBlueColor // the color of the blinking cursor
            field.textColor = ColorUtils.darkGreyColor
            field.lineColor = ColorUtils.darkGreyColor
            field.selectedTitleColor = ColorUtils.overcastBlueColor
            field.selectedLineColor = ColorUtils.overcastBlueColor
            
            field.lineHeight = 1.0 // bottom line height in points
            field.selectedLineHeight = 1.0
            field.text = ""
            field.delegate = self
        }
        
        emailTextField.iconType = .image
        emailTextField.iconImage = #imageLiteral(resourceName: "email")
        
        passwordTextField.iconType = .image
        passwordTextField.iconImage = #imageLiteral(resourceName: "password")
        
        nameTextField.addBlackDot()
        emailTextField.addBlackDot()
        passwordTextField.addBlackDot()
        
        createAccountButton.clipsToBounds = true
        createAccountButton.layer.cornerRadius = 30
        createAccountButton.layer.borderWidth = 0.5
        createAccountButton.layer.borderColor = UIColor.init(white: 0.2, alpha: 0.2).cgColor
    }
    
    // MARK: UI Events
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onTermsClicked(_ sender: Any) {
        termsButton.setImage(#imageLiteral(resourceName: "checked_icon"), for: .normal)
        termsAgreed = true
    }
    
    @IBAction func onRegister(_ sender: Any) {
        if (nameTextField.text == "") {
            SVProgressHUD.showError(withStatus: "Please enter your nickname.")
            return
        } else if (emailTextField.text == "") {
            SVProgressHUD.showError(withStatus: "Please enter your email.")
            return
        } else if (!InputValidator.isValidEmail(emailTextField.text!)) {
            SVProgressHUD.showError(withStatus: "Please enter valid email address.")
            return
        }
        
        if (passwordTextField.text == "") {
            SVProgressHUD.showError(withStatus: "Please enter your password.")
            return
        } else if ((passwordTextField.text?.count)! < 6) {
            SVProgressHUD.showError(withStatus: "Password should at least 6 characters.")
            return
        }
        
        if (termsAgreed == false) {
            SVProgressHUD.showError(withStatus: "Please read and accept Terms and Privacy Policy.")
            return
        }
        
        SVProgressHUD.show(withStatus: "Creating Account...")
        ApiManager.register(email: emailTextField.text, success: {
            SVProgressHUD.dismiss()            
            self.performSegue(withIdentifier: "VerifyView", sender: nil)
        }) { (error) in
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: error)
        }
    }
    
}
