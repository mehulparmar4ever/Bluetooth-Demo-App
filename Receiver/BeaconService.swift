//
//  BeaconService.swift
//  Receiver
//
//  Created by Pavel Kazantsev on 8/12/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

enum StateChanged {
    case monitoring
    case outside
    case inside(distance: Double)
}
extension StateChanged: CustomStringConvertible {
    var description: String {
        switch self {
        case .monitoring: return "Monitoring..."
        case .outside: return "Outside of range."
        case .inside(let distance): return "Inside of range. Accuracy: \(distance)"
        }
    }
}

class BeaconService: NSObject {

    private var locationManager: CLLocationManager?
    fileprivate var stateChanged: ((StateChanged) -> Void)?

    func start(_ stateChangeCallback: @escaping (StateChanged) -> Void) {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        stateChanged = stateChangeCallback
    }

    fileprivate func monitorBeacons() {
        guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) else {
            print("Beacon monitoring is not available")
            return
        }

        let proximityUUID = UUID(uuidString: senderUuidString)!

        let region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: beaconID)
        locationManager?.startMonitoring(for: region)
    }

}

extension BeaconService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Authorization status: \(status.rawValue)")
        if status == .notDetermined {
            manager.requestAlwaysAuthorization()
        } else {
            monitorBeacons()
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("did determine state \(state.rawValue) for region: \(region)")
        if state == .outside {
            stateChanged?(.outside)
        } else if state == .inside {
            stateChanged?(.inside(distance: 0.0))
        } else {
            stateChanged?(.monitoring)
        }
    }

}
