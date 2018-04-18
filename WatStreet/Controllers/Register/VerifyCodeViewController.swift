//
//  VerifyCodeViewController.swift
//  WatStreet
//
//  Created by Eric on 12/17/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import SVProgressHUD
import SkyFloatingLabelTextField

class VerifyCodeViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var codeTextField: BlackDotTextField!
    @IBOutlet weak var verifyCodeButton: UIButton!
    
    var isFromForgot: Bool!
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
        codeTextField.delegate = self
        
        codeTextField.backgroundColor = UIColor.clear
        codeTextField.tintColor = ColorUtils.overcastBlueColor // the color of the blinking cursor
        codeTextField.textColor = ColorUtils.darkGreyColor
        codeTextField.lineColor = ColorUtils.lightGreyColor
        codeTextField.selectedTitleColor = ColorUtils.overcastBlueColor
        codeTextField.selectedLineColor = ColorUtils.overcastBlueColor
        codeTextField.addBlackDot()
        
        codeTextField.lineHeight = 1.0 // bottom line height in points
        codeTextField.selectedLineHeight = 1.0
        codeTextField.text = ""
        
        verifyCodeButton.clipsToBounds = true
        verifyCodeButton.layer.cornerRadius = 30
        verifyCodeButton.layer.borderWidth = 0.5
        verifyCodeButton.layer.borderColor = UIColor.init(white: 0.2, alpha: 0.2).cgColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is PasswordResetViewController) {
            let controller = segue.destination as! PasswordResetViewController
            
            controller.userInfo = self.userInfo
        }
    }
    // MARK: UI Events
    
    @IBAction func onVerifyCode(_ sender: Any) {
        if (self.isFromForgot) {
            self.onVerifyCode()
        } else {
            self.onVerifyAccount()
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func onVerifyAccount() {
        SVProgressHUD.show(withStatus: "Veirying Code...")
        ApiManager.verify(user: userInfo!, code: codeTextField.text, success: {
            ApiManager.login(email: self.userInfo!.email, password: self.userInfo!.password, success: {
                SVProgressHUD.dismiss()
                self.performSegue(withIdentifier: "MainView", sender: nil)
            }, error: { (error) in
                SVProgressHUD.dismiss()
                SVProgressHUD.showError(withStatus: error)
            })
        }) { (error) in
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: error)
        }
    }
    
    func onVerifyCode() {
        SVProgressHUD.show(withStatus: "Veirying Code...")
        ApiManager.verifyForgot(email: userInfo!.email, code: codeTextField.text, success: { (token) in
            SVProgressHUD.dismiss()
            self.userInfo!.token = token
            self.performSegue(withIdentifier: "PasswordResetView", sender: nil)
        }) { (error) in
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: error)
        }
    }
}
