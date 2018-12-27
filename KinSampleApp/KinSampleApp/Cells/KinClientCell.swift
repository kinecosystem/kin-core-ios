//
//  KinClientCell.swift
//  KinSampleApp
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import UIKit
import KinCoreSDK

protocol KinClientCellDelegate: class {
    func revealKeyStore()
    func startSendTransaction()
    func deleteAccountTapped()
    func recentTransactionsTapped()
    func burnAccountTapped(cell: KinClientCell)
    func getTestKin(cell: KinClientCell)
}

class KinClientCell: UITableViewCell {
    weak var kinClientCellDelegate: KinClientCellDelegate?
    var kinClient: KinClient!
    var kinAccount: KinAccount!
}

