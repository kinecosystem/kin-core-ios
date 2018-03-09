//
//  SendTransactionViewController.swift
//  KinSampleApp
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import UIKit
import KinSDK
import StellarKit
import KinUtil

class SendTransactionViewController: UIViewController {
    var kinAccount: KinAccount!

    @IBOutlet weak var sendButton: UIButton!

    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var memoTextField: UITextField!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sendButton.fill(with: view.tintColor)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        amountTextField.becomeFirstResponder()
    }

    @IBAction func sendTapped(_ sender: Any) {
        let amount = UInt64(amountTextField.text ?? "0") ?? 0
        let address = addressTextField.text ?? ""

        promise(curry(kinAccount.sendTransaction)(address)(Decimal(amount))(memoTextField.text))
            .then(on: DispatchQueue.main, handler: { [weak self] transactionId in
                let message = "Transaction with ID \(transactionId) sent to \(address)"
                let alertController = UIAlertController(title: "Transaction Sent", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Copy Transaction ID", style: .default, handler: { _ in
                    UIPasteboard.general.string = transactionId
                }))
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            })
            .error(handler: { error in
                DispatchQueue.main.async { [weak self] in
                    let alertController = UIAlertController(title: "Error",
                                                            message: self?.stringForError(error),
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                }
            })
    }

    @IBAction func pasteTapped(_ sender: Any) {
        addressTextField.text = UIPasteboard.general.string
    }

    func stringForError(_ error: Error?) -> String {
        guard let error = error else {
            return "No transaction ID"
        }

        if let sError = error as? StellarError {
            switch sError {
            case .missingPublicKey:
                return "Misisng public key"
            case .missingHash:
                return "Transaction hash not found"
            case .missingSequence:
                return "Unable to retrieve sequence"
            case .missingBalance:
                return "Balance for asset not found"
            case .urlEncodingFailed:
                return "Unable to encode data for URL request"
            case .dataEncodingFailed:
                return "Unable to code string as Data"
            case .signingFailed:
                return "Signing failed"
            case .destinationNotReadyForAsset (let e, _):
                if let e = e as? StellarError {
                    switch e {
                    case .missingAccount:
                        return "Account not found"
                    case .missingBalance:
                        return "No KIN trustline"
                    default:
                        break
                    }
                }
            case .unknownError:
                return "Unknown error"
            default:
                break
            }
        }

        if let pError = error as? PaymentError {
            switch pError {
            case .PAYMENT_UNDERFUNDED:
                return "Insufficient funds"
            default:
                return error.localizedDescription
            }
        }

        return error.localizedDescription
    }
}

extension SendTransactionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let notDigitsSet = CharacterSet.decimalDigits.inverted
        let containsNotADigit = string.unicodeScalars.contains(where: notDigitsSet.contains)

        return !containsNotADigit
    }
}
