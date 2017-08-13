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

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startMonitoring()
    }

    private func startMonitoring() {
        guard let service = beaconService else {
            return
        }

        service.start { [weak self] state in
            self?.statusLabel.text = String(describing: state)
            self?.locationChanged(state)
        }
    }

    private func locationChanged(_ state: StateChanged) {
        if case let .inside(model) = state {
            latestBeaconModel = model
            if unlockTimer == nil {
                print("Started 'unlock the door' timer")
                let timer = Timer(timeInterval: unlockTime, target: self, selector: #selector(unlockTheDoor), userInfo: nil, repeats: true)
                RunLoop.main.add(timer, forMode: .defaultRunLoopMode)
                self.unlockTimer = timer
            }
        } else {
            latestBeaconModel = nil
            if let timer = unlockTimer {
                print("Removed 'unlock the door' timer")
                unlockTimer = nil
                timer.invalidate()
            }
        }
    }

    @objc func unlockTheDoor() {
        guard let model = latestBeaconModel, model.proximity != .unknown, model.minor == 1, model.accuracy <= 0.5 else {
            print("Do not unlock the door")
            return
        }

        print("Unlock the door")
        lockService?.unlock { response in
            if let responseMessage = response {
                print("Unlock result: \(responseMessage)")
            } else {
                print("Door not unlocked :(")
            }
        }
    }

}

