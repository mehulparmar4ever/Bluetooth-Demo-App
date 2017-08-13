//
//  LockService.swift
//  Receiver
//
//  Created by Pavel Kazantsev on 8/13/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import Foundation

class LockService {

    private let network: NetworkService

    init(network: NetworkService) {
        self.network = network
    }

    func unlock(_ callback: @escaping (String?) -> Void) {
        network.unlockTheDoor(callback)
    }

}
