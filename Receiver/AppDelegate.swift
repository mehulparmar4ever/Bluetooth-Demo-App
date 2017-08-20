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

    var network: NetworkService!
    var beaconService: BeaconService!
    var lockService: LockService!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        network = NetworkService()
        beaconService = BeaconService()
        lockService = LockService(network: network)

        if let tabVc = window?.rootViewController as? UITabBarController {
            if let rootVc = tabVc.viewControllers?[0] as? ViewController {
                rootVc.beaconService = beaconService
                rootVc.lockService = lockService
            }
        }

        return true
    }

}

