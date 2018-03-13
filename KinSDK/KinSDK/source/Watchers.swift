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
    private let paymentWatch: StellarKit.PaymentWatch
    private let linkBag = LinkBag()

    public let emitter: Observable<Decimal>

    init(stellar: Stellar, account: String, balance: Decimal) {
        var balance = balance

        self.paymentWatch = stellar.paymentWatch(account: account, lastEventId: "now")

        self.emitter = paymentWatch.emitter
            .filter({ $0.asset == stellar.asset && $0.source != $0.destination })
            .map({
                balance += $0.amount * ($0.source == account ? -1 : 1)

                return balance
            })

        self.emitter.add(to: linkBag)
    }
}

public class CreationWatch {
    private let paymentWatch: StellarKit.PaymentWatch
    private let linkBag = LinkBag()

    public let emitter: Observable<Bool>

    init(stellar: Stellar, account: String) {
        self.paymentWatch = stellar.paymentWatch(account: account, lastEventId: nil)

        self.emitter = paymentWatch.emitter
            .map({ _ in
                return true
            })

        self.emitter.add(to: linkBag)
    }
}

