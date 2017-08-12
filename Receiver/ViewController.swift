//
//  ViewController.swift
//  Receiver
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

        startMonitoring()
    }

    private func startMonitoring() {
        guard let service = beaconService else {
            return
        }

        service.start { [weak self] state in
            self?.statusLabel.text = String(describing: state)
        }
    }

}

