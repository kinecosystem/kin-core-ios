//
//  KinSampleViewController.swift
//  KinSampleApp
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import UIKit
import KinSDK
import StellarKit

class KinSampleViewController: UITableViewController {
    private var kinClient: KinClient!
    private var kinAccount: KinAccount!

    class func instantiate(with kinClient: KinClient, kinAccount: KinAccount) -> KinSampleViewController {
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "KinSampleViewController") as? KinSampleViewController else {
            fatalError("Couldn't load KinSampleViewController from Main.storyboard")
        }

        viewController.kinClient = kinClient
        viewController.kinAccount = kinAccount

        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        tableView.tableFooterView = UIView()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if let kCell = cell as? KinClientCell {
            kCell.kinClient = kinClient
            kCell.kinAccount = kinAccount
            kCell.kinClientCellDelegate = self
        }
        
        return cell
    }
}

extension KinSampleViewController: KinClientCellDelegate {
    func revealKeyStore() {
        guard let keyStoreViewController = storyboard?.instantiateViewController(withIdentifier: "KeyStoreViewController") as? KeyStoreViewController else {
            return
        }

        keyStoreViewController.view.tintColor = view.tintColor
        keyStoreViewController.kinClient = kinClient
        navigationController?.pushViewController(keyStoreViewController, animated: true)
    }

    func startSendTransaction() {
        guard let txViewController = storyboard?.instantiateViewController(withIdentifier: "SendTransactionViewController") as? SendTransactionViewController else {
            return
        }

        txViewController.view.tintColor = view.tintColor
        txViewController.kinAccount = kinAccount
        navigationController?.pushViewController(txViewController, animated: true)
    }

    func deleteAccountTapped() {
        let alertController = UIAlertController(title: "Delete Wallet?",
                                                message: "Deleting a wallet will cause funds to be lost",
                                                preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "OK", style: .destructive) { _ in
            try? self.kinClient.deleteAccount(at: 0, with: KinAccountPassphrase)
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    func getTestKin(cell: KinClientCell) {
        guard let getKinCell = cell as? GetKinTableViewCell else {
            return
        }

        getKinCell.getKinButton.isEnabled = false

        let user_id = UUID().uuidString

        print("Creating account.")

        DispatchQueue(label: "").async {
            self.createAccount(user_id: user_id)
                .then { result -> Any? in
                    print("Activating account.")

                    return self.activate()
                }
                .then { result -> Any? in
                    print("Funding account")

                    return self.fund(user_id: user_id)
                }
                .then { result -> Void in
                    DispatchQueue.main.async {
                        getKinCell.getKinButton.isEnabled = true

                        if let balanceCell = self.tableView.visibleCells.flatMap({ $0 as? BalanceTableViewCell }).first {
                            balanceCell.refreshBalance(self)
                        }
                    }
                }
                .error { error in
                    DispatchQueue.main.async {
                        getKinCell.getKinButton.isEnabled = true

                        if let balanceCell = self.tableView.visibleCells.flatMap({ $0 as? BalanceTableViewCell }).first {
                            balanceCell.refreshBalance(self)
                        }
                    }
            }
        }
    }

    enum OnBoardingError: Error {
        case invalidResponse
        case errorResponse
        case activationFailed
    }

    private func createAccount(user_id: String) -> Promise {
        let p = Promise()

        let content = [
            "user_id": user_id,
            "public_address": kinAccount.publicAddress,
            ]
        let body = try! JSONSerialization.data(withJSONObject: content, options: [])

        let url = URL(string: "http://188.166.34.7:8000/create_account")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard
                let data = data,
                let jsonOpt = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonOpt as? [String: Any]
                else {
                    print("Unable to parse json.")

                    p.signal(OnBoardingError.invalidResponse)

                    return
            }

            guard let status = json["status"] as? String, status == "ok" else {
                p.signal(OnBoardingError.errorResponse)

                return
            }

            p.signal(true)
        }).resume()

        return p
    }

    private func activate() -> Promise {
        let p = Promise()

        kinAccount.activate(passphrase: KinAccountPassphrase, completion: { txHash, error in
            if let error = error {
                print("Activation failed: \(error)")

                p.signal(OnBoardingError.activationFailed)

                return
            }

            p.signal(true)
        })

        return p
    }

    private func fund(user_id: String) -> Promise {
        let p = Promise()

        let content = [
            "user_id": user_id,
            "public_address": kinAccount.publicAddress,
            ]
        let body = try! JSONSerialization.data(withJSONObject: content, options: [])

        let url = URL(string: "http://188.166.34.7:8000/fund")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard
                let data = data,
                let jsonOpt = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonOpt as? [String: Any]
                else {
                    print("Unable to parse json.")

                    p.signal(OnBoardingError.invalidResponse)

                    return
            }

            guard let status = json["status"] as? String, status == "ok" else {
                p.signal(OnBoardingError.errorResponse)

                return
            }

            p.signal(true)
        }).resume()

        return p
    }
}
