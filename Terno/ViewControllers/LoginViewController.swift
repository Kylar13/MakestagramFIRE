//
//  LoginViewController.swift
//  Terno
//
//  Created by Ramon Pans on 07/07/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class LoginViewController: UIViewController {
	
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

		emailTextField.text = ""
		passwordTextField.text = ""
		
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func loginButtonPressed(sender: AnyObject) {
		
		if Global.isValidEmail(emailTextField.text!) {
			if !passwordTextField.text!.isEmpty {
				
				FIRAuth.auth()?.signInWithEmail(emailTextField.text!, password: passwordTextField.text!) {
					(user, error) in
					if let user = user {
						// User is signed in.
						Global.email = user.email!
						Global.uid = user.uid
						Global.username = user.displayName!
						print("User with email \(Global.email) logged in!")
						
						Global.storage = FIRStorage.storage()
						Global.databaseRef = FIRDatabase.database().reference()
						
						self.performSegueWithIdentifier("loginSuccessful", sender: self)
						
					} else {
						print("Unable to log in")
						
						//Give some kind of feedback to user
						
						//Clear text fields
						self.emailTextField.text! = ""
						self.passwordTextField.text! = ""
					}
				}
			}
		}
	}
	

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
