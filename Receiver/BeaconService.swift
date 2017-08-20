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
        return "Proximity: \(proximity.description)\nAccuracy: \(accuracy)\nMajor:\(major)\nMinor:\(minor)"
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

    var deviceMode: DeviceBluetoothMode = .beacon

    private var locationManager: CLLocationManager?

    fileprivate var centralManager: CBCentralManager?
    fileprivate var stateChanged: ((StateChanged) -> Void)?
    fileprivate var monitoredRegion: CLBeaconRegion!
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var keyCharacteristic: CBCharacteristic?
    fileprivate var unlockResultCharacteristic: CBCharacteristic?

    fileprivate var readValueCallback: ((Int) -> Void)?

    func start(_ stateChangeCallback: @escaping (StateChanged) -> Void) {
        print("Started as \(deviceMode)")
        prepareForReuse()
        if deviceMode == .beacon {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        } else {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        stateChanged = stateChangeCallback
    }
    func stop() {
        stateChanged = nil
        prepareForReuse()
    }

    private func prepareForReuse() {
        centralManager = nil
        locationManager = nil
        connectedPeripheral = nil
        keyCharacteristic = nil
        unlockResultCharacteristic = nil
    }

    func readValue(_ callback: @escaping (Int) -> Void) {
        readValueCallback = callback
        // Should connect before reading
        if let manager = centralManager, let peripheral = connectedPeripheral {
            manager.connect(peripheral)
        }
    }
    func writeValue(_ value: String) {
        guard let peripheral = connectedPeripheral,
            let char = unlockResultCharacteristic,
            let data = value.data(using: .ascii) else { return }

        // We should be still connected after a read
        peripheral.writeValue(data, for: char, type: .withResponse)
        print("Sent.")
    }

    func disconnect() {
        guard let connected = connectedPeripheral, let manager = centralManager else { return }

        manager.cancelPeripheralConnection(connected)
        keyCharacteristic = nil
        unlockResultCharacteristic = nil
        print("Disconnected")
    }

    fileprivate func monitorBeacons() {
        guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) else {
            print("Beacon monitoring is not available")
            return
        }
        print("Monitoring beacons...")

        let proximityUUID = UUID(uuidString: senderUuidString)!

        let region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: beaconID)
        monitoredRegion = region
        locationManager?.startMonitoring(for: region)
    }

}

// MARK: - Beacon part
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
        } else if region.identifier == monitoredRegion.identifier,
                !manager.rangedRegions.contains(monitoredRegion),
                CLLocationManager.isRangingAvailable() {
            // FIXME: Duplication!
            manager.startRangingBeacons(in: monitoredRegion)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == monitoredRegion.identifier, CLLocationManager.isRangingAvailable() {
            manager.startRangingBeacons(in: monitoredRegion)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == monitoredRegion.identifier {
            manager.stopRangingBeacons(in: monitoredRegion)
            stateChanged?(.outside)
        }
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let nearestBeacon = beacons.first else {
            return // No beacons?
        }
        let major = CLBeaconMajorValue(nearestBeacon.major)
        let minor = CLBeaconMinorValue(nearestBeacon.minor)

        let model = BeaconModel(major: major, minor: minor, proximity: nearestBeacon.proximity, accuracy: nearestBeacon.accuracy)
//        print("\(model)")
        stateChanged?(.inside(model))
    }

}

// MARK: - Bluetooth LE part
extension BeaconService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("\(central.state): \(central.state.rawValue)")

        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [CBUUID(string: senderUuidString)], options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        connectedPeripheral = peripheral
        peripheral.delegate = self

        central.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unnamed")")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let err = error {
            print("Connection error: \(err)")
        } else {
            print("Could not connect to \(String(describing: peripheral.name))")
        }
    }

}

extension BeaconService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let byte = value.first {
            print("Value is \(byte)")
            readValueCallback?(Int(byte))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("Could not write value: \(err)")
        } else {
            disconnect()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Updated notification state for \(characteristic)")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services = peripheral.services ?? []
        services.filter { $0.uuid.uuidString == senderUuidString }.forEach { service in
            print("Discover characteristics...")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

//    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
//        print("RSSI is \(RSSI)")
//    }
//
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristics = service.characteristics ?? []
        for char in characteristics {
            if char.uuid.uuidString == characteristicUuid {
                keyCharacteristic = char
                print("Read value for \(char)")
                peripheral.readValue(for: char)
            } else if char.uuid.uuidString == unlockStatusCharacteristicUuid {
                unlockResultCharacteristic = char
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        disconnect()
    }
}
