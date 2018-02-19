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
    private var filteredTxs: [PaymentInfo]?

    private var paymentWatch: PaymentWatch?

    var kinAccount: KinAccount!

    func add(tx: PaymentInfo) {
        txs.insert(tx, at: 0)

        while txs.count > 100 {
            txs.remove(at: txs.count - 1)
        }

        filteredTxs?.insert(tx, at: 0)

        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        paymentWatch = try? kinAccount.watch(cursor: nil)
        paymentWatch?.onMessage = { [weak self] paymentInfo in
            guard let me = self else {
                return
            }

            me.add(tx: paymentInfo)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTxs?.count ?? txs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tx = filteredTxs?[indexPath.row] ?? txs[indexPath.row]

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

extension RecentTxsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        if let text = textField.text, text.isEmpty == false {
            let filter: (PaymentInfo) -> Bool = { paymentInfo in
                if let memo = paymentInfo.memo, let string = String(bytes: memo, encoding: .utf8) {
                    return string.contains(text)
                }

                return false
            }

            filteredTxs = txs.filter(filter)
            tableView.reloadData()

            paymentWatch?.filter = filter
        }
        else {
            paymentWatch?.filter = { _ in true }
            filteredTxs = nil
            
            tableView.reloadData()
        }

        return true
    }
}
