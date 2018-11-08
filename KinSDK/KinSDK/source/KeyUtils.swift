//
//  KeyUtils.swift
//  KinCoreSDK
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit

enum KeyUtilsError: Error {
    case encodingFailed (String)
    case decodingFailed (String)
    case hashingFailed
    case passphraseIncorrect
    case unknownError
    case signingFailed
}

public struct KeyUtils {
    public static func keyPair(from seed: Data) -> Sign.KeyPair? {
        return Sodium().sign.keyPair(seed: seed.array)
    }

    public static func keyPair(from seed: String) -> Sign.KeyPair? {
        return Sodium().sign.keyPair(seed: StellarKit.KeyUtils.key(base32: seed).array)
    }

    public static func seed(from passphrase: String,
                            encryptedSeed: String,
                            salt: String) throws -> Data {
        guard let encryptedSeedData = Data(hexString: encryptedSeed) else {
            throw KeyUtilsError.decodingFailed(encryptedSeed)
        }

        let sodium = Sodium()

        let skey = try KeyUtils.keyHash(passphrase: passphrase, salt: salt)

        guard let seed = sodium.secretBox.open(nonceAndAuthenticatedCipherText: encryptedSeedData.array,
                                               secretKey: skey.array) else {
                                                throw KeyUtilsError.passphraseIncorrect
        }

        return Data(seed)
    }

    public static func keyHash(passphrase: String, salt: String) throws -> Data {
        guard let passphraseData = passphrase.data(using: .utf8) else {
            throw KeyUtilsError.encodingFailed(passphrase)
        }

        guard let saltData = Data(hexString: salt) else {
            throw KeyUtilsError.decodingFailed(salt)
        }

        let sodium = Sodium()

        guard let hash = sodium.pwHash.hash(outputLength: 32,
                                            passwd: passphraseData.array,
                                            salt: saltData.array,
                                            opsLimit: sodium.pwHash.OpsLimitInteractive,
                                            memLimit: sodium.pwHash.MemLimitInteractive) else {
                                                throw KeyUtilsError.hashingFailed
        }

        return Data(hash)
    }

    public static func encryptSeed(_ seed: Data, secretKey: Data) -> Data? {
        guard let bytes: Bytes = Sodium().secretBox.seal(message: seed.array, secretKey: secretKey.array) else {
            return nil
        }

        return Data(bytes)
    }

    public static func seed() -> Data? {
        if let bytes = Sodium().randomBytes.buf(length: 32) {
            return Data(bytes: bytes)
        }

        return nil
    }

    public static func salt() -> String? {
        if let bytes = Sodium().randomBytes.buf(length: 16) {
            return Data(bytes).hexString
        }

        return nil
    }

    public static func sign(message: Data, signingKey: Data) throws -> Data {
        guard let signature = Sodium().sign.signature(message: message.array, secretKey: signingKey.array) else {
            throw KeyUtilsError.signingFailed
        }

        return Data(signature)
    }
}

