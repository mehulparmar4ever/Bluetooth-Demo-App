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

private let minorValueSwitchTime: TimeInterval = 10.0

class BeaconService: NSObject {

    private var peripheralManager: CBPeripheralManager?
    private var startedCallback: (() -> Void)?
    private weak var timer: Timer?

    private var currentRegion: CLBeaconRegion?

    func start(_ started: @escaping () -> Void) {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        startedCallback = started
    }

    fileprivate func startAdvertising(on manager: CBPeripheralManager) {
        let minor: CLBeaconMinorValue
        if let currRegion = currentRegion, let currMinor = currRegion.minor?.uint16Value {
            minor = (currMinor == 0 ? 1 : 0)
        } else {
            minor = 0
        }
        if manager.state == .poweredOn, let region = BeaconService.createBeaconRegion(minor: minor) {
            currentRegion = region
            advertiseDevice(region: region, on: manager)
        }
    }

    fileprivate class func createBeaconRegion(major: CLBeaconMajorValue = 1, minor: CLBeaconMinorValue = 0) -> CLBeaconRegion? {
        let proximityUUID = UUID(uuidString: senderUuidString)!
        print("Advertise with minor: \(minor)")

        return CLBeaconRegion(proximityUUID: proximityUUID, major: major, minor: minor, identifier: beaconID)
    }

    fileprivate func advertiseDevice(region: CLBeaconRegion, on manager: CBPeripheralManager) {
        //guard !manager.isAdvertising else { return }

        let peripheralData = (region.peripheralData(withMeasuredPower: nil) as NSDictionary) as! [String : Any]
        manager.startAdvertising(peripheralData)

        if timer == nil {
            startTimer(with: manager)
        }
    }

    private func startTimer(with manager: CBPeripheralManager) {
        let timer = Timer(timeInterval: minorValueSwitchTime, target: self, selector: #selector(updateAdvertising), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .defaultRunLoopMode)
        self.timer = timer
    }

    fileprivate func startedAdvertising() {
        startedCallback?()
    }

    @objc fileprivate func updateAdvertising() {
        guard let peripheral = peripheralManager else { return }

        peripheral.stopAdvertising()

        startAdvertising(on: peripheral)
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

        startAdvertising(on: peripheral)
    }
}
