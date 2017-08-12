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

struct BeaconModel {
    let major: CLBeaconMajorValue
    let minor: CLBeaconMinorValue
    let proximity: CLProximity
    let accuracy: CLLocationAccuracy
}
extension BeaconModel: CustomStringConvertible {
    var description: String {
        return "Proximity: \(proximity)\nAccuracy: \(accuracy)"
    }
}
extension BeaconModel {
    static var empty: BeaconModel {
        return BeaconModel(major: 0, minor: 0, proximity: .unknown, accuracy: -0.0)
    }
}

enum StateChanged {
    case monitoring
    case outside
    case inside(BeaconModel)
}
extension StateChanged: CustomStringConvertible {
    var description: String {
        switch self {
        case .monitoring: return "Monitoring..."
        case .outside: return "Outside of range."
        case .inside(let beaconInfo): return String(describing: beaconInfo)
        }
    }
}

private extension CLProximity {
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .immediate: return "Close"
        case .near: return "Near"
        case .far: return "Far"
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
        if status == .notDetermined {
            manager.requestAlwaysAuthorization()
        } else {
            monitorBeacons()
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .outside {
            stateChanged?(.outside)
        } else if state == .unknown {
            stateChanged?(.monitoring)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion, CLLocationManager.isRangingAvailable() {
            manager.startRangingBeacons(in: beaconRegion)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            manager.stopRangingBeacons(in: beaconRegion)
        }
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let nearestBeacon = beacons.first else {
            return // No beacons?
        }
        let major = CLBeaconMajorValue(nearestBeacon.major)
        let minor = CLBeaconMinorValue(nearestBeacon.minor)

        stateChanged?(.inside(BeaconModel(major: major, minor: minor, proximity: nearestBeacon.proximity, accuracy: nearestBeacon.accuracy)))
    }

}
