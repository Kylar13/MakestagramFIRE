//
//  SignUpViewController.swift
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

class SignUpViewController: UIViewController {

	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var rPasswordTextField: UITextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		usernameTextField.text = ""
		emailTextField.text = ""
		passwordTextField.text = ""
		rPasswordTextField.text = ""

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func signUpButtonPressed(sender: AnyObject) {
		
		//Check for fields correct. Regex??
		if Global.isValidEmail(emailTextField.text!) {
			if passwordTextField.text! == rPasswordTextField.text! && !passwordTextField.text!.isEmpty {
				
				FIRAuth.auth()?.createUserWithEmail(emailTextField.text!, password: passwordTextField.text!) { FIRAuthResultCallback in
					
					if let user = FIRAuthResultCallback.0 {
						//Add username to the user
						let changeRequest = user.profileChangeRequest()
						changeRequest.displayName = self.usernameTextField.text!
						changeRequest.commitChangesWithCompletion() { error in
							if error == nil {
								//Redirect to other tab bar following segue
								Global.email = user.email!
								Global.uid = user.uid
								Global.username = user.displayName!
								//print("User with email \(Global.email) logged in!")
								
								Global.storage = FIRStorage.storage()
								Global.databaseRef = FIRDatabase.database().reference()
								
								Global.databaseRef?.child("allUsers").child(Global.uid).setValue(Global.username)
								Global.databaseRef?.child("search").child(Global.uid).setValue(Global.username.lowercaseString)
								
								self.performSegueWithIdentifier("signUpSuccessful", sender: self)
							}
						}
					}
					//TODO: If an error ocurred, give feedback to the user
					self.usernameTextField.text = ""
					self.emailTextField.text = ""
					self.passwordTextField.text = ""
					self.rPasswordTextField.text = ""
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
