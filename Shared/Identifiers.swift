//
//  Identifiers.swift
//  Sender
//
//  Created by Pavel Kazantsev on 8/12/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import Foundation

let senderUuidString = "601E5EE6-F55C-4649-95E3-0BAED5580091"
let characteristicUuid = "EDD2956A-34D4-4D93-B495-CB2F67D3558A"
let unlockStatusCharacteristicUuid = "F2FD8840-4A0B-4BB7-B2C2-4B4E6489D39F"

let beaconID = "net.pakaz.kisi.Sender"

enum DeviceBluetoothMode {
    case beacon
    case ble
}
