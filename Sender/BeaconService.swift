//
//  BeaconService.swift
//  Sender
//
//  Created by Pavel Kazantsev on 8/12/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

class BeaconService: NSObject {

    private var peripheralManager: CBPeripheralManager?
    private var startedCallback: (() -> Void)?

    func start(_ started: @escaping () -> Void) {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        startedCallback = started
    }

    fileprivate func createBeaconRegion() -> CLBeaconRegion? {
        let proximityUUID = UUID(uuidString: senderUuidString)!
        let major : CLBeaconMajorValue = 1
        let minor : CLBeaconMinorValue = 0

        return CLBeaconRegion(proximityUUID: proximityUUID, major: major, minor: minor, identifier: beaconID)
    }

    fileprivate func advertiseDevice(region : CLBeaconRegion) {
        let peripheralData = (region.peripheralData(withMeasuredPower: nil) as NSDictionary) as! [String : Any]

        peripheralManager?.startAdvertising(peripheralData)
    }

    fileprivate func startedAdvertising() {
        startedCallback?()
    }

}

extension BeaconService: CBPeripheralManagerDelegate {

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let anErr = error {
            print("Advertising error: \(anErr)")
        } else {
            startedAdvertising()
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("\(peripheral.state): \(peripheral.state.rawValue)")

        if peripheral.state == .poweredOn, let region = createBeaconRegion() {
            advertiseDevice(region: region)
        }
    }
}
