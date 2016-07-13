//
//  Global.swift
//  Terno
//
//  Created by Ramon Pans on 29/06/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import FirebaseDatabase

class Global {
	static var username: String = ""
	static var email: String = ""
	static var photoUrl: NSURL?
	static var uid: String = ""
	
	static var storage: FIRStorage?
	static var databaseRef: FIRDatabaseReference?
	
	static var startQuery: Double = 0
	
	static var searchArray: [User] = []
	
	static func isValidEmail(testStr:String) -> Bool {
		// print("validate calendar: \(testStr)")
		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
		
		let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
		return emailTest.evaluateWithObject(testStr)
	}
}