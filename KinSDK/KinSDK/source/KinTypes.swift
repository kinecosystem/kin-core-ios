//
//  KinTypes.swift
//  KinCoreSDK
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

public enum AccountStatus: Int {
    case notCreated
    case notActivated
    case activated
}

public struct PaymentInfo {
    private let txEvent: TxEvent
    private let account: String
    private let asset: Asset

    public var createdAt: Date {
        return txEvent.created_at
    }

    public var credit: Bool {
        return account == destination
    }

    public var debit: Bool {
        return !credit
    }

    public var source: String {
        return txEvent.payments.filter({ $0.asset == asset }).first?.source ?? txEvent.source_account
    }

    public var hash: String {
        return txEvent.hash
    }

    public var amount: Decimal {
        return txEvent.payments.filter({ $0.asset == asset }).first?.amount ?? Decimal(0)
    }

    public var destination: String {
        return txEvent.payments.filter({ $0.asset == asset }).first?.destination ?? ""
    }

    public var memoText: String? {
        return txEvent.memoText
    }

    public var memoData: Data? {
        return txEvent.memoData
    }

    init(txEvent: TxEvent, account: String, asset: Asset) {
        self.txEvent = txEvent
        self.account = account
        self.asset = asset
    }
}

/**
 Ensures the validity of the app id from the host application.
 
 The host application should pass a four character string. The string can only contain any combination
 of lowercase letters, uppercase letters and digits.
 */
public struct AppId {
    let value: String
    
    public init(_ value: String) throws {
        // Lowercase and uppercase letters + numbers
        let charSet = CharacterSet.lowercaseLetters.union(.uppercaseLetters).union(.decimalDigits)
        
        guard value == value.trimmingCharacters(in: charSet.inverted),
            value.rangeOfCharacter(from: charSet) != nil,
            value.utf8.count == 4
            else {
                throw KinError.invalidAppId
        }
        
        self.value = value
    }
}

extension AppId {
    public var memoPrefix: String {
        return "1-\(value)-"
    }
}

extension Memo {
    public static func prependAppIdIfNeeded(_ appId: AppId, to memo: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "^1-[A-z0-9]{3,4}-.*") {
            let range = NSRange(location: 0, length: memo.count)
            
            if regex.firstMatch(in: memo, options: [], range: range) != nil {
                return memo
            }
        }
        
        return appId.memoPrefix + memo
    }
}

public typealias LinkBag = KinUtil.LinkBag
public typealias Promise = KinUtil.Promise
public typealias Observable<T> = KinUtil.Observable<T>
