//
//  AppDelegate.swift
//  Receiver
//
//  Created by Pavel Kazantsev on 8/11/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var service: BeaconService!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        service = BeaconService()

        if let rootVc = window?.rootViewController as? ViewController {
            rootVc.beaconService = service
        }

        return true
    }

}

