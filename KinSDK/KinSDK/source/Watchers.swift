//
//  Watchers.swift
//  KinSDK
//
//  Created by Avi Shevin on 26/02/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit
import KinUtil

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
            .map({ return PaymentInfo(txInfo: $0, account: account) })
            .pausable(limit: 1000)

        self.emitter.add(to: linkBag)
    }
}

public class BalanceWatch {
    private var paymentWatch: PaymentWatch
    private var balance: Decimal = 0
    private var linkBag = LinkBag()

    public let emitter = Observable<Decimal>()

    init(stellar: Stellar, account: String) {
        self.paymentWatch = PaymentWatch(stellar: stellar, account: account)

        paymentWatch.emitter
            .on(next: { [weak self] paymentInfo in
                guard let me = self else {
                    return
                }

                me.balance += paymentInfo.amount * (paymentInfo.debit ? -1 : 1)
                me.emitter.next(me.balance)
            })
            .add(to: linkBag)
    }
}
