//
//  BurnAccountCell.swift
//  KinSampleApp
//
//  Created by Corey Werner on 27/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit

class BurnAccountCell: KinClientCell {
    @IBOutlet weak var burnAccountButton: UIButton!

    override func tintColorDidChange() {
        super.tintColorDidChange()

        burnAccountButton.fill(with: tintColor)
    }

    @IBAction func burnAccountTapped(_ sender: Any) {
        kinClientCellDelegate?.burnAccountTapped(cell: self)
    }
}
