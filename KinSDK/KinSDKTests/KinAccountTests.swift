//
//  KinAccountTests.swift
//  KinTestHostTests
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import XCTest
@testable import KinCoreSDK
@testable import StellarKit
import KinUtil

class KinAccountTests: XCTestCase {

    var kinClient: KinClient!
    let passphrase = UUID().uuidString

    var account0: KinAccount?
    var account1: KinAccount?
    var issuer: StellarAccount?

    let endpoint = "http://localhost:8000"
    let sNetworkId: StellarKit.NetworkId = .custom("private testnet")
    lazy var node = Stellar.Node(baseURL: URL(string: endpoint)!, networkId: sNetworkId)

    lazy var kNetworkId = KinCoreSDK.NetworkId.custom(issuer: "GBSJ7KFU2NXACVHVN2VWQIXIV5FWH6A7OIDDTEUYTCJYGY3FJMYIDTU7",
                                                      stellarNetworkId: sNetworkId)

    override func setUp() {
        super.setUp()

        kinClient = try! KinClient(with: URL(string: endpoint)!,
                                   networkId: kNetworkId)

        KeyStore.removeAll()

        if KeyStore.count() > 0 {
            XCTAssertTrue(false, "Unable to clear existing accounts!")
        }

        self.account0 = try? kinClient.addAccount()
        self.account1 = try? kinClient.addAccount()

        if account0 == nil || account1 == nil {
            XCTAssertTrue(false, "Unable to create account(s)!")
        }

        issuer = try? KeyStore.importSecretSeed("SAXSDD5YEU6GMTJ5IHA6K35VZHXFVPV6IHMWYAQPSEKJRNC5LGMUQX35",
                                                passphrase: passphrase)

        if issuer == nil {
            XCTAssertTrue(false, "Unable to import issuer account!")
        }

        try! obtain_kin_and_lumens(for: (account0 as! KinStellarAccount))
        try! obtain_kin_and_lumens(for: (account1 as! KinStellarAccount))
    }

    override func tearDown() {
        super.tearDown()

        kinClient.deleteKeystore()
    }

    func sendTransaction(from account: KinAccount,
                         to recipient: String,
                         kin: Decimal,
                         memo: String? = nil) throws -> TransactionId {
        let txClosure = { (txComp: @escaping TransactionCompletion) in
            account.sendTransaction(to: recipient, kin: kin, memo: memo, completion: txComp)
        }

        if let txHash = try serialize(txClosure) {
            return txHash
        }

        throw KinError.unknown
    }

    func getBalance(_ account: KinAccount) throws -> Balance {
        if let balance: Decimal = try serialize(account.balance) {
            return balance
        }

        throw KinError.unknown
    }

    func fund(account: String) -> Promise<String> {
        let funderPK = "GCLBBAIDP34M4JACPQJUYNSPZCQK7IRHV7ETKV6U53JPYYUIIVDVJJFQ"
        let funderSK = "SDBDJVXHPVQGDXYHEVOBBV4XZUDD7IQTXM5XHZRLXRJVY5YMH4YUCNZC"

        let sourcePK = PublicKey.PUBLIC_KEY_TYPE_ED25519(WrappedData32(KeyUtils.key(base32: funderPK)))

        let funder = try! KeyStore.importSecretSeed(funderSK, passphrase: passphrase)
        funder.sign = { message in
            return try funder.sign(message: message, passphrase: self.passphrase)
        }

        return Stellar.sequence(account: funderPK, node: node)
            .then { sequence in
                let tx = Transaction(sourceAccount: sourcePK,
                                     seqNum: sequence,
                                     timeBounds: nil,
                                     memo: .MEMO_NONE,
                                     operations: [Operation.createAccount(destination: account,
                                                                          balance: 100 * 10000000)])

                let envelope = try Stellar.sign(transaction: tx,
                                                signer: funder,
                                                node: self.node)

                return Stellar.postTransaction(envelope: envelope, node: self.node)
        }
    }

    func obtain_kin_and_lumens(for account: KinStellarAccount) throws {
        let group = DispatchGroup()
        group.enter()

        var e: Error?

        let asset = Asset(assetCode: "KIN", issuer: kNetworkId.issuer)!

        guard let issuer = issuer else {
            throw KinError.unknown
        }

        fund(account: account.stellarAccount.publicKey!)
            .then { txHash -> Void in
                account.activate() { txHash, error in
                    if let error = error {
                        e = error

                        group.leave()

                        return
                    }

                    issuer.sign = { message in
                        return try issuer.sign(message: message,
                                               passphrase: self.passphrase)
                    }

                    return Stellar.payment(source: issuer,
                                           destination: account.stellarAccount.publicKey!,
                                           amount: 100 * 10000000,
                                           asset: asset,
                                           node: self.node)
                        .error { error in
                            e = error
                        }
                        .finally {
                            group.leave()
                    }
                }
            }
            .error { error in
                e = error

                group.leave()
        }

        group.wait()

        if let error = e {
            throw error
        }
    }

    func wait_for_non_zero_balance(account: KinAccount) throws -> Balance {
        var balance: Decimal = try getBalance(account)

        let exp = expectation(for: NSPredicate(block: { _, _ in
            do {
                balance = try self.getBalance(account)
            }
            catch {
                XCTAssertTrue(false, "Something went wrong: \(error)")
            }

            return balance > 0
        }), evaluatedWith: balance, handler: nil)

        self.wait(for: [exp], timeout: 120)

        return balance
    }

    func test_extra_data() {
        let a1 = kinClient.accounts[0]
        a1?.extra = Data([1, 2, 3])

        let a2 = kinClient.accounts[0]

        XCTAssertEqual(Data([1, 2, 3]), a2?.extra)
    }

    func test_balance_sync() {
        do {
            var balance: Decimal? = try getBalance(account0!)

            if balance == 0 {
                balance = try wait_for_non_zero_balance(account: account0!)
            }

            XCTAssertNotEqual(balance, 0)
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }

    func test_balance_async() {
        var balanceChecked: Balance? = nil
        let expectation = self.expectation(description: "wait for callback")

        do {
            _ = try wait_for_non_zero_balance(account: account0!)

            account0?.balance { balance, _ in
                balanceChecked = balance
                expectation.fulfill()
            }

            self.waitForExpectations(timeout: 25.0)

            XCTAssertNotEqual(balanceChecked, 0)
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }

    func test_balance_promise() {
        var balanceChecked: Balance? = nil
        let expectation = self.expectation(description: "wait for callback")

        do {
            _ = try wait_for_non_zero_balance(account: account0!)

            account0?.balance()
                .then{ balance in
                    balanceChecked = balance
                }
                .finally({
                    expectation.fulfill()
                })

            self.waitForExpectations(timeout: 25.0)

            XCTAssertNotEqual(balanceChecked, 0)
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }

    func test_send_transaction_with_nil_memo() {
        let sendAmount: Decimal = 5

        do {
            guard
                let account0 = account0,
                let account1 = account1 else {
                    XCTAssertTrue(false, "No accounts to use.")
                    return
            }

            var startBalance0: Decimal = try getBalance(account0)
            var startBalance1: Decimal = try getBalance(account1)

            if startBalance0 == 0 {
                startBalance0 = try wait_for_non_zero_balance(account: account0)
            }

            if startBalance1 == 0 {
                startBalance1 = try wait_for_non_zero_balance(account: account1)
            }

            let txId = try sendTransaction(from: account0,
                                           to: account1.publicAddress,
                                           kin: sendAmount,
                                           memo: nil) as TransactionId?

            XCTAssertNotNil(txId)

            let balance0: Decimal = try getBalance(account0)
            let balance1: Decimal = try getBalance(account1)

            XCTAssertEqual(balance0, startBalance0 - sendAmount)
            XCTAssertEqual(balance1, startBalance1 + sendAmount)
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }

    func test_send_transaction_with_memo() {
        let sendAmount: Decimal = 5

        do {
            guard
                let account0 = account0,
                let account1 = account1 else {
                    XCTAssertTrue(false, "No accounts to use.")
                    return
            }

            var startBalance0: Decimal = try getBalance(account0)
            var startBalance1: Decimal = try getBalance(account1)

            if startBalance0 == 0 {
                startBalance0 = try wait_for_non_zero_balance(account: account0)
            }

            if startBalance1 == 0 {
                startBalance1 = try wait_for_non_zero_balance(account: account1)
            }

            let txId = try sendTransaction(from: account0,
                                           to: account1.publicAddress,
                                           kin: sendAmount,
                                           memo: "memo") as TransactionId?

            XCTAssertNotNil(txId)

            let balance0: Decimal = try getBalance(account0)
            let balance1: Decimal = try getBalance(account1)

            XCTAssertEqual(balance0, startBalance0 - sendAmount)
            XCTAssertEqual(balance1, startBalance1 + sendAmount)
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }

    func test_send_transaction_with_empty_memo() {
        let sendAmount: Decimal = 5

        do {
            guard
                let account0 = account0,
                let account1 = account1 else {
                    XCTAssertTrue(false, "No accounts to use.")
                    return
            }

            var startBalance0: Decimal = try getBalance(account0)
            var startBalance1: Decimal = try getBalance(account1)

            if startBalance0 == 0 {
                startBalance0 = try wait_for_non_zero_balance(account: account0)
            }

            if startBalance1 == 0 {
                startBalance1 = try wait_for_non_zero_balance(account: account1)
            }

            let txId = try sendTransaction(from: account0,
                                           to: account1.publicAddress,
                                           kin: sendAmount,
                                           memo: "") as TransactionId?

            XCTAssertNotNil(txId)

            let balance0: Decimal = try getBalance(account0)
            let balance1: Decimal = try getBalance(account1)

            XCTAssertEqual(balance0, startBalance0 - sendAmount)
            XCTAssertEqual(balance1, startBalance1 + sendAmount)
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }

    func test_send_transaction_with_insufficient_funds() {
        do {
            guard
                let account0 = account0,
                let account1 = account1 else {
                    XCTAssertTrue(false, "No accounts to use.")
                    return
            }

            let balance: Decimal = try getBalance(account0)

            do {
                _ = try sendTransaction(from: account0,
                                        to: account1.publicAddress,
                                        kin: balance * 10000000 + 1,
                                        memo: nil) as TransactionId?

                XCTAssertTrue(false,
                              "Tried to send kin with insufficient funds, but didn't get an error")
            }
            catch {
                guard case KinError.insufficientFunds = error else {
                    XCTAssertTrue(false,
                                  "Tried to send kin, and got error, but not .insufficientFunds: \(error)")

                    return
                }
            }
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }

    func test_send_transaction_of_zero_kin() {
        guard
            let account0 = account0,
            let account1 = account1 else {
                XCTAssertTrue(false, "No accounts to use.")
                return
        }

        do {
            _ = try sendTransaction(from: account0,
                                    to: account1.publicAddress,
                                    kin: 0,
                                    memo: nil) as TransactionId?
            XCTAssertTrue(false,
                          "Tried to send kin with insufficient funds, but didn't get an error")
        }
        catch {
            if let kinError = error as? KinError,
                case KinError.invalidAmount = kinError {
            } else {
                XCTAssertTrue(false,
                              "Received unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func test_use_after_delete_balance() {
        do {
            let account = kinClient.accounts[0]

            try kinClient.deleteAccount(at: 0)
            _ = try getBalance(account!)

            XCTAssert(false, "An exception should have been thrown.")
        }
        catch {
            if let kinError = error as? KinError,
                case KinError.accountDeleted = kinError {
            } else {
                XCTAssertTrue(false,
                              "Received unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func test_use_after_delete_transaction() {
        do {
            let account = kinClient.accounts[0]
            
            try kinClient.deleteAccount(at: 0)
            _ = try sendTransaction(from: account!, to: "", kin: 1, memo: nil)

            XCTAssert(false, "An exception should have been thrown.")
        }
        catch {
            if let kinError = error as? KinError,
                case KinError.accountDeleted = kinError {
            } else {
                XCTAssertTrue(false,
                              "Received unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func test_export() {
        do {
            let account = try kinClient.addAccount()
            let data = try account.export(passphrase: passphrase)

            XCTAssertNotNil(data, "Unable to retrieve keyStore account: \(String(describing: account))")
        }
        catch {
            XCTAssertTrue(false, "Something went wrong: \(error)")
        }
    }
}
