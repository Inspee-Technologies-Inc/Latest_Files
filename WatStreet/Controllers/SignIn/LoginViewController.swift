//
//  LoginViewController.swift
//  WatStreet
//

import UIKit
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import SkyFloatingLabelTextField

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: BlackDotTextField!
    @IBOutlet weak var passwordTextField: BlackDotTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var rememberButton: UIButton!
    @IBOutlet weak var forgetPasswordButton: UIButton!
    
    var rememberPassword: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
        
        if (Auth.auth().currentUser != nil) {
            SVProgressHUD.show(withStatus: "Loading...")
            ApiManager.loadUser(user: Auth.auth().currentUser, success: {
                SVProgressHUD.dismiss()
                if let mapViewController = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") {
                    self.navigationController?.pushViewController(mapViewController, animated: true)
                }
            })
            
            ApiManager.shared.setDeviceToken()
        }
    }
    
    // MARK: Initialization
    
    func initUI() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        rememberPassword = false
        let textFields = [emailTextField, passwordTextField]
        
        for field in textFields {
            field?.backgroundColor = UIColor.clear
            field?.tintColor = ColorUtils.overcastBlueColor // the color of the blinking cursor
            field?.textColor = ColorUtils.darkGreyColor
            field?.lineColor = ColorUtils.darkGreyColor
            field?.lineHeight = 0.5
            field?.selectedTitleColor = ColorUtils.overcastBlueColor
            field?.selectedLineColor = ColorUtils.overcastBlueColor
            
            field?.lineHeight = 1.0 // bottom line height in points
            field?.selectedLineHeight = 1.0
            field?.text = ""
            field?.addBlackDot()
        }
        
        loginButton.clipsToBounds = true
        loginButton.layer.cornerRadius = 30
        loginButton.layer.borderWidth = 0.5
        loginButton.layer.borderColor = UIColor.init(white: 0.2, alpha: 0.2).cgColor
        
        let (remember, email, password) = PasswordManager.savedLogin()
        rememberPassword = !remember
        self.onRememberPassword(rememberButton)
        emailTextField.text = email
        passwordTextField.text = password
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: UI Events
    
    @IBAction func logInAction(_ sender: Any) {
        self.view.endEditing(true)
        if (emailTextField.text == "") {
            SVProgressHUD.showError(withStatus: "Please enter your email.")
        } else if (!InputValidator.isValidEmail(emailTextField.text!)) {
            SVProgressHUD.showError(withStatus: "Please enter valid email address.")
        } else if (passwordTextField.text == "") {
            SVProgressHUD.showError(withStatus: "Please enter your password.")
        }
        
        SVProgressHUD.show(withStatus: "Logging In...")
        ApiManager.login(email: emailTextField.text, password: passwordTextField.text, success: {
            SVProgressHUD.dismiss()
            if (self.rememberPassword == true) {
                PasswordManager.saveLogin(self.emailTextField.text, password: self.passwordTextField.text)
            } else {
                PasswordManager.removeLogin()
                self.emailTextField.text = ""
                self.passwordTextField.text = ""
            }
            
            if let mapViewController = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") {
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(mapViewController, animated: true)
                }
            }
        }) { (error) in
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: error)
            
            self.forgetPasswordButton.isHidden = false
        }
    }
    
    @IBAction func onPasswordChanged(_ sender: Any) {
        if (passwordTextField.text == "") {
            forgetPasswordButton.isHidden = false
        } else {
            forgetPasswordButton.isHidden = true
        }
    }
    
    @IBAction func onRememberPassword(_ sender: Any) {
        if (rememberPassword) {
            rememberPassword = false
            rememberButton.setImage(#imageLiteral(resourceName: "unchecked_icon"), for: .normal)
        } else {
            rememberPassword = true
            rememberButton.setImage(#imageLiteral(resourceName: "checked_icon"), for: .normal)
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
