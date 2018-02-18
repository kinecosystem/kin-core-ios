//
//  RecentTxsTableViewController.swift
//  KinSampleApp
//
//  Created by Avi Shevin on 15/02/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import UIKit
import KinSDK

class RecentTxsTableViewController: UITableViewController {
    private var txs = [PaymentInfo]()
    var kinAccount: KinAccount!

    func add(tx: PaymentInfo) {
        txs.insert(tx, at: 0)

        while txs.count > 100 {
            txs.remove(at: txs.count - 1)
        }

        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return txs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tx = txs[indexPath.row]

        let cell: TxCell

        let reuseIdentifier = tx.source == kinAccount.publicAddress
            ? "OutgoingCell"
            : "IncomingCell"

        cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TxCell

        cell.addressLabel.text = tx.source == kinAccount.publicAddress ? tx.destination : tx.source
        cell.amountLabel.text = String(describing: tx.amount)
        cell.dateLabel.text = tx.createdAt

        if let memo = tx.memo {
            cell.memoLabel.text = String(bytes: memo, encoding: .utf8)
        }
        else {
            cell.memoLabel.text = nil
        }

        return cell
    }
}
