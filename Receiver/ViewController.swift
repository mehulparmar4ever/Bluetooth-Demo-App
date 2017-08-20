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

    private let unlockAnimationView = UnlockAnimationView()

    var beaconService: BeaconService?
    var lockService: LockService?

    private var unlockTimer: Timer?
    private var latestBeaconModel: BeaconModel?
    private var deviceMode: DeviceBluetoothMode = .beacon {
        didSet {
            beaconService?.deviceMode = deviceMode
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(unlockAnimationView)
        unlockAnimationView.translatesAutoresizingMaskIntoConstraints = false
        unlockAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        unlockAnimationView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: nil) { [weak self] note in
            self?.stopTimer()
            self?.beaconService?.stop()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil) { [weak self] note in
            self?.startMonitoring()
        }
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

    private func playUnlockAnimation() {
        DispatchQueue.main.async {
            self.unlockAnimationView.play()
        }
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
            NSLog("Start timer as device mode changed to BLE")
            startTimer()
            statusLabel.text = "Bluetooth LE mode"
        }
    }

    private func locationChanged(_ state: StateChanged) {
        if case let .inside(model) = state {
            latestBeaconModel = model
            if unlockTimer == nil {
                NSLog("Start timer from locationChanged(_:)")
                startTimer()
            }
        } else {
            latestBeaconModel = nil
            stopTimer()
        }
    }

    private func startTimer() {
        NSLog("Started 'unlock the door' timer")
        unlockTimer?.invalidate()
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
        NSLog("Unlock the door called")
        unlockConditionsMet { [weak self] shouldUnlock in
            guard shouldUnlock else {
                NSLog("Start timer as should not unlock")
                self?.startTimer()
                return
            }
            NSLog("Unlock the door...")
            self?.lockService?.unlock { response in
                if let responseMessage = response {
                    self?.playUnlockAnimation()
                    print("Unlock result: \(responseMessage). Send to Sender…")
                    self?.beaconService?.writeValue(responseMessage)
                } else {
                    print("Door not unlocked :(")
                }
                NSLog("Start timer as unlocked")
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
                print("read value: \(value)")
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

