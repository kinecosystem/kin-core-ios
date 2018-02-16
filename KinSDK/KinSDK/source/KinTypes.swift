//
//  KinMisc.swift
//  KinSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit

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

    init(txInfo: TxInfo) {
        self.txInfo = txInfo
    }
}

public class PaymentWatch {
    public let filter: (PaymentInfo) -> PaymentInfo? = { $0 }
    public var onMessage: ((PaymentInfo) -> Void)? = nil

    public var paused: Bool = false {
        didSet {
            if paused == false {
                while buffer.isEmpty == false {
                    onMessage?(buffer[0])
                    buffer.remove(at: 0)
                }
            }
        }
    }

    private let stellar: Stellar
    private var buffer = [PaymentInfo]()

    init(stellar: Stellar, account: String) {
        self.stellar = stellar

        stellar.watch(account: account) { [weak self] txInfo in
            guard let me = self else {
                return
            }

            if txInfo.isPayment {
                guard let paymentInfo = me.filter(PaymentInfo(txInfo: txInfo)) else {
                    return
                }

                if me.paused {
                    me.buffer.append(paymentInfo)

                    while me.buffer.count > 1000 {
                        me.buffer.remove(at: 0)
                    }
                }
                else {
                    me.onMessage?(paymentInfo)
                }
            }
        }
    }

    deinit {
        stellar.cancelWatch()
    }
}
