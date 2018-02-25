//
//  KinMisc.swift
//  KinSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit
import KinUtil

/**
 A protocol to encapsulate the formation of the endpoint `URL` and the `NetworkId`.
 */
public protocol ServiceProvider {
    /**
     The `URL` of the block chain node.
     */
    var url: URL { get }

    /**
     The `NetworkId` to be used.
     */
    var networkId: NetworkId { get }
}

public typealias Balance = Decimal
public typealias TransactionId = String

/**
 Closure type used by the send transaction API upon completion, which contains a `TransactionId` in
 case of success, or an error in case of failure.
 */
public typealias TransactionCompletion = (TransactionId?, Error?) -> Void

/**
 Closure type used by the balance API upon completion, which contains the `Balance` in case of
 success, or an error in case of failure.
 */
public typealias BalanceCompletion = (Balance?, Error?) -> Void

public struct PaymentInfo {
    let txInfo: TxInfo

    public var createdAt: String {
        return txInfo.createdAt
    }

    public var source: String {
        return txInfo.source
    }

    public var hash: String {
        return txInfo.hash
    }

    public var amount: Decimal {
        guard let txAmount = txInfo.amount else {
            return Decimal(0)
        }

        return Decimal(txAmount) / Decimal(KinMultiplier)
    }

    public var destination: String {
        return txInfo.destination ?? ""
    }

    public var memoText: String? {
        return txInfo.memoText
    }

    public var memoData: Data? {
        return txInfo.memoData
    }

    init(txInfo: TxInfo) {
        self.txInfo = txInfo
    }
}

public class PaymentWatch {
    private var txWatch: TxWatch!
    private var linkBag = LinkBag()

    public let emitter: PausableObserver<PaymentInfo>

    public var paused: Bool {
        get {
            return emitter.paused
        }

        set {
            emitter.paused = newValue
        }
    }

    public var cursor: String? {
        return txWatch.eventSource.lastEventId
    }

    init(stellar: Stellar, account: String, cursor: String? = nil) {
        self.txWatch = stellar.watch(account: account, lastEventId: cursor)

        self.emitter = self.txWatch.emitter
            .filter({ $0.isPayment && $0.asset == "KIN" })
            .map({ return PaymentInfo(txInfo: $0) })
            .pausable(limit: 1000)

        self.emitter.add(to: linkBag)
    }
}
