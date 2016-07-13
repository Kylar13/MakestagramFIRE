//
//  AppDelegate.swift
//  Terno
//
//  Created by Ramon Pans on 29/06/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import IQKeyboardManagerSwift
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		
		FIRApp.configure()
		Fabric.with([Answers.self, Crashlytics.self])
		
		IQKeyboardManager.sharedManager().enable = true
		
		
		//TODO: Add a logout button
		//try! FIRAuth.auth()?.signOut()

		
		if let user = FIRAuth.auth()?.currentUser {
			
			
			Global.email = user.email!
			Global.uid = user.uid
			Global.username = user.displayName!
			
			Global.storage = FIRStorage.storage()
			Global.databaseRef = FIRDatabase.database().reference()
			
			//try! FIRAuth.auth()?.signOut()
			
			//Go straight to the other tab bar controller
			let storyboard = UIStoryboard(name: "Main", bundle: nil)

			self.window?.rootViewController = storyboard.instantiateViewControllerWithIdentifier("Timeline") as! UITabBarController
			self.window?.makeKeyAndVisible()
		}
		
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

