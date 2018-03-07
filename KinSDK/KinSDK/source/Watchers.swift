//
//  Watchers.swift
//  KinSDK
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit
import KinUtil

public class PaymentWatch {
    private let txWatch: TxWatch
    private let linkBag = LinkBag()

    public let emitter: Observable<PaymentInfo>

    public var cursor: String? {
        return txWatch.eventSource.lastEventId
    }

    init(stellar: Stellar, account: String, asset: Asset? = nil, cursor: String? = nil) {
        self.txWatch = stellar.txWatch(account: account, lastEventId: cursor)

        self.emitter = self.txWatch.emitter
            .filter({ ti in
                ti.payments.count > 0 && ti.payments
                    .filter({ $0.asset == asset ?? stellar.asset }).count > 0
            })
            .map({ return PaymentInfo(txInfo: $0, account: account, asset: asset ?? stellar.asset) })

        self.emitter.add(to: linkBag)
    }
}

public class BalanceWatch {
    private let paymentWatch: PaymentWatch
    private let linkBag = LinkBag()

    public let emitter: Observable<Decimal>

    private static func debit(_ account: String, paymentInfo: PaymentInfo) -> Bool {
        return paymentInfo.source == account
    }

    init(stellar: Stellar, account: String) {
        var balance: Decimal = 0
        var sequence: UInt64 = UInt64.max

        self.paymentWatch = PaymentWatch(stellar: stellar, account: account)

        self.emitter = paymentWatch.emitter
            .filter({ return $0.sequence > sequence && $0.source != $0.destination })
            .map({
                balance += $0.amount * ($0.debit ? -1 : 1)

                return balance
            })

        self.emitter.add(to: linkBag)
        
        stellar.accountDetails(account: account)
            .then(handler: { [weak self] details in
                balance = details.balances
                    .filter({ $0.asset == stellar.asset }).first?.balanceNum ?? Decimal(0)

                sequence = details.seqNum

                self?.emitter.next(balance)
            })
    }
}
