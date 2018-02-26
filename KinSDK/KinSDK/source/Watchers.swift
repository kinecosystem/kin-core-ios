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
            .filter({ (ti: TxInfo) in ti.isPayment && ti.asset == "KIN" })
            .map({ return PaymentInfo(txInfo: $0, account: account) })
            .pausable(limit: 1000)

        self.emitter.add(to: linkBag)
    }
}

public class BalanceWatch {
    private var paymentWatch: PaymentWatch

    public let emitter: Observable<(balance: Decimal, sequence: UInt64)>

    init(stellar: Stellar, account: String, sequence: UInt64? = nil) {
        self.paymentWatch = PaymentWatch(stellar: stellar, account: account)

        var balance: Decimal = 0

        self.emitter = paymentWatch.emitter
            .on(next: { balance += $0.amount * ($0.debit ? -1 : 1) })
            .filter({ return sequence != nil && $0.sequence > sequence! || true })
            .map({ return (balance: balance, sequence: $0.sequence) })
    }
}
