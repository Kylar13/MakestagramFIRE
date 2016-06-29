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

class Global {
	static var username: String = ""
	static var email: String = ""
	static var photoUrl: NSURL?
	static var uid: String = ""
	
	static var storage: FIRStorage?
	static var databaseRef: FIRDatabaseReference?
}