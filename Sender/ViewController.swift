//
//  ViewController.swift
//  Sender
//
//  Created by Pavel Kazantsev on 8/11/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var statusLabel: UILabel!

    var beaconService: BeaconService?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startBeacon()
    }
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        var newMode: DeviceBluetoothMode? = nil
        if sender.selectedSegmentIndex == 0 {
            newMode = .beacon
        } else if sender.selectedSegmentIndex == 1 {
            newMode = .ble
        }
        if let mode = newMode {
            beaconService?.deviceMode = mode
            startBeacon()
        }
    }

    private func startBeacon() {
        guard let service = beaconService else {
            return
        }

        service.start { [weak self] newState in
            self?.statusLabel.text = newState.description
        }
    }

}

extension StateChanged: CustomStringConvertible {
    var description: String {
        switch self {
        case .started: return "Advertising"
        case .responded(let responseValue): return "Unlock response: \(responseValue)"
        case .subscribed: return "Got Subscriber"
        case .unsubscribed: return "No Subscribers"
        }
    }
}

