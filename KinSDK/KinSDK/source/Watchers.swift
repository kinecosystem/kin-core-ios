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

    init(node: Stellar.Node, account: String, asset: Asset, cursor: String? = nil) {
        self.txWatch = Stellar.txWatch(account: account, lastEventId: cursor, node: node)

        self.emitter = self.txWatch.emitter
            .filter({ ti in
                ti.payments.count > 0 && ti.payments
                    .filter({ $0.asset == asset }).count > 0
            })
            .map({ return PaymentInfo(txInfo: $0, account: account, asset: asset) })

        self.emitter.add(to: linkBag)
    }
}

public class BalanceWatch {
    private let paymentWatch: StellarKit.PaymentWatch
    private let linkBag = LinkBag()

    public let emitter: StatefulObserver<Decimal>

    init(node: Stellar.Node, account: String, balance: Decimal, asset: Asset) {
        var balance = balance

        self.paymentWatch = Stellar.paymentWatch(account: account, lastEventId: "now", node: node)

        self.emitter = paymentWatch.emitter
            .filter({ $0.asset == asset && $0.source != $0.destination })
            .map({
                balance += $0.amount * ($0.source == account ? -1 : 1)

                return balance
            })
            .stateful()

        self.emitter.add(to: linkBag)

        self.emitter.next(balance)
    }
}

public class CreationWatch {
    private let paymentWatch: StellarKit.PaymentWatch
    private let linkBag = LinkBag()

    public let emitter: Observable<Bool>

    init(node: Stellar.Node, account: String) {
        self.paymentWatch = Stellar.paymentWatch(account: account, lastEventId: nil, node: node)

        self.emitter = paymentWatch.emitter
            .map({ _ in
                return true
            })

        self.emitter.add(to: linkBag)
    }
}

