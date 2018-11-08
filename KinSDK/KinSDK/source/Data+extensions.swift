//
// Data+extensions.swift
// KinCoreSDK
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

public extension Data {
    var array: [UInt8] {
        var a = [UInt8]()

        withUnsafeBytes {
            a = $0.pointee
        }
        
        return a
    }
}
