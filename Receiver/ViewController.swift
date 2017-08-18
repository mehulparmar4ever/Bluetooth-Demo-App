//
//  ViewController.swift
//  Receiver
//
//  Created by Pavel Kazantsev on 8/11/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import UIKit

private let unlockTime: TimeInterval = 4.0

class ViewController: UIViewController {

    @IBOutlet private weak var statusLabel: UILabel!

    var beaconService: BeaconService?
    var lockService: LockService?

    private weak var unlockTimer: Timer?
    private var latestBeaconModel: BeaconModel?
    private var deviceMode: DeviceBluetoothMode = .beacon {
        didSet {
            beaconService?.deviceMode = deviceMode
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startMonitoring()
    }
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            deviceMode = .beacon
        } else if sender.selectedSegmentIndex == 1 {
            deviceMode = .ble
        }
        startMonitoring()
    }

    private func startMonitoring() {
        guard let service = beaconService else {
            return
        }
        stopTimer()

        service.start { [weak self] state in
            self?.statusLabel.text = String(describing: state)
            if let mode = self?.deviceMode, mode == .beacon {
                self?.locationChanged(state)
            }
        }

        if deviceMode == .ble {
            startTimer()
        }
    }

    private func locationChanged(_ state: StateChanged) {
        if case let .inside(model) = state {
            latestBeaconModel = model
            if unlockTimer == nil {
                startTimer()
            }
        } else {
            latestBeaconModel = nil
            stopTimer()
        }
    }

    private func startTimer() {
        print("Started 'unlock the door' timer")
        let timer = Timer(timeInterval: unlockTime, target: self, selector: #selector(unlockTheDoor), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .defaultRunLoopMode)
        unlockTimer = timer

    }
    private func stopTimer() {
        if let timer = unlockTimer {
            print("Removed 'unlock the door' timer")
            unlockTimer = nil
            timer.invalidate()
        }
    }

    @objc func unlockTheDoor() {
        unlockConditionsMet { [weak self] shouldUnlock in
            guard shouldUnlock else {
                self?.startTimer()
                return
            }
            print("Unlock the door...")
            self?.lockService?.unlock { response in
                if let responseMessage = response {
                    print("Unlock result: \(responseMessage). Send to Sender…")
                    self?.beaconService?.writeValue(responseMessage)
                } else {
                    print("Door not unlocked :(")
                }
                self?.startTimer()
            }
        }
    }

    private func unlockConditionsMet(_ callback: @escaping (Bool) -> Void) {
        switch deviceMode {
        case .beacon:
            guard let model = latestBeaconModel else { return }
            let shouldUnlock = model.proximity != .unknown && model.minor == 1 && model.accuracy <= 0.5
            callback(shouldUnlock)
        case .ble:
            guard let service = beaconService else { return }
            service.readValue { value in
                if value != 1 {
                    print("Got 0. Disconnect.")
                    service.disconnect()
                }
                let shouldUnlock = (value == 1)
                callback(shouldUnlock)
            }
        }
    }

}

