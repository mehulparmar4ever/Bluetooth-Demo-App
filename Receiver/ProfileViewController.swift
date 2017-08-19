//
//  ProfileViewController.swift
//  Receiver
//
//  Created by Pavel Kazantsev on 8/18/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import UIKit

class ProfileViewController: UITableViewController {

    @IBOutlet private var profileImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let image = #imageLiteral(resourceName: "profile-image")
        let profieImage = prepareProfileImage(from: image)
        profileImageView.image = profieImage
    }

    private func prepareProfileImage(from image: UIImage) -> UIImage {
        return image.roundedImage()
    }
}

extension UIImage {

    func roundedImage() -> UIImage {
        let scale = UIScreen.main.scale
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        UIBezierPath(roundedRect: rect, cornerRadius: size.height / 2).addClip()
        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

}

