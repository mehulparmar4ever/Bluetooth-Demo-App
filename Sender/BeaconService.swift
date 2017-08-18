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

enum StateChanged {
    case started
    case responded(String)
    case subscribed
    case unsubscribed
}

class BeaconService: NSObject {
    var deviceMode: DeviceBluetoothMode = .beacon

    private var peripheralManager: CBPeripheralManager?
    private weak var timer: Timer?
    private var mainCharacteristic: CBMutableCharacteristic?

    fileprivate var currentValue: UInt8 = 0
    fileprivate var stateChangedCallback: ((StateChanged) -> Void)?

    private var currentRegion: CLBeaconRegion?

    func start(_ started: @escaping (StateChanged) -> Void) {
        print("Started as \(deviceMode)")
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        stateChangedCallback = started
    }

    fileprivate func startAdvertising(on manager: CBPeripheralManager) {
        switch deviceMode {
        case .beacon: advertiseBeacon(on: manager)
        case .ble: addBluetoothService(on: manager)
        }
    }
    private func advertiseBeacon(on manager: CBPeripheralManager) {
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

    fileprivate func addBluetoothService(on manager: CBPeripheralManager) {
        guard manager.state == .poweredOn else { return }

        let service = createService()
        manager.add(service)
    }

    fileprivate class func createBeaconRegion(major: CLBeaconMajorValue = 1, minor: CLBeaconMinorValue = 0) -> CLBeaconRegion? {
        let proximityUUID = UUID(uuidString: senderUuidString)!
        print("Advertise with minor: \(minor)")

        return CLBeaconRegion(proximityUUID: proximityUUID, major: major, minor: minor, identifier: beaconID)
    }

    fileprivate func createService() -> CBMutableService {
        let service = CBMutableService(type: CBUUID(string: senderUuidString), primary: true)
        let markerChar = CBMutableCharacteristic(type: CBUUID(string: characteristicUuid),
                                               properties: [.read, .notify],
                                               value: nil,
                                               permissions: [.readEncryptionRequired])
        let unlockStatusChar = CBMutableCharacteristic(type: CBUUID(string: unlockStatusCharacteristicUuid),
                                                       properties: [.write, .notify],
                                                       value: nil,
                                                       permissions: [.writeEncryptionRequired])
        mainCharacteristic = markerChar
        service.characteristics = [markerChar, unlockStatusChar]
        return service
    }
    fileprivate func advertiseDevice(region: CLBeaconRegion, on manager: CBPeripheralManager) {
        //guard !manager.isAdvertising else { return }

        let peripheralData = (region.peripheralData(withMeasuredPower: nil) as NSDictionary) as! [String : Any]
        manager.startAdvertising(peripheralData)

        if timer == nil {
            startTimer(with: manager)
        }
    }

    fileprivate func advertiseDevice(service: CBService, on manager: CBPeripheralManager) {
        let peripheralData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [service.uuid] as NSArray,
                                             CBAdvertisementDataLocalNameKey: "Beacon Sender"]
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
        stateChangedCallback?(.started)
    }

    @objc fileprivate func updateAdvertising() {
        guard let peripheral = peripheralManager else { return }

        if deviceMode == .beacon {
            peripheral.stopAdvertising()
            startAdvertising(on: peripheral)
        }
        else if deviceMode == .ble {
            currentValue = currentValue == 0 ? 1 : 0
            print("Next value is \(currentValue)")
        }
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

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let anErr = error {
            print("Add service error: \(anErr)")
        } else {
            //print("Service \(service.uuid) is added")
            advertiseDevice(service: service, on: peripheral)
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("\(peripheral.state): \(peripheral.state.rawValue)")

        startAdvertising(on: peripheral)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid.uuidString == characteristicUuid else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }

        let data: [UInt8] = [currentValue]
        request.value = Data(bytes: data)
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let recognizedRequests = requests.filter { $0.characteristic.uuid.uuidString == unlockStatusCharacteristicUuid }
        guard let aRequest = recognizedRequests.first else {
            if let anyRequest = requests.first {
                peripheral.respond(to: anyRequest, withResult: .attributeNotFound)
            }
            return
        }
        if let data = aRequest.value, let responseStr = String(data: data, encoding: .ascii) {
            stateChangedCallback?(.responded(responseStr))
        }
        if let anyRequest = requests.first {
            peripheral.respond(to: anyRequest, withResult: .success)
        }
    }

}
