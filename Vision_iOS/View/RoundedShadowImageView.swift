//
//  RoundedShadowImageView.swift
//  Vision_iOS
//
//  Created by Sohel Dhengre on 07/02/18.
//  Copyright © 2018 Sohel Dengre. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.75
        self.layer.shadowRadius = 15
        self.layer.cornerRadius = 15
    }

}
