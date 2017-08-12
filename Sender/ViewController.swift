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

    private func startBeacon() {
        guard let service = beaconService else {
            return
        }

        service.start { [weak self] in
            self?.statusLabel.text = "Advertising"
        }
    }

}

