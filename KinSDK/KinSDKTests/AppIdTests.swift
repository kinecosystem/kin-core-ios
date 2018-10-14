//
// AppIdTests.swift
// KinCoreSDK
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import KinCoreSDK

class AppIdTests: XCTestCase {

    func test_app_id_not_valid() {
        XCTAssertThrowsError(try AppId(""))
        XCTAssertThrowsError(try AppId("a"))
        XCTAssertThrowsError(try AppId("aa"))
        XCTAssertThrowsError(try AppId("aaa"))
        XCTAssertThrowsError(try AppId("aaa "))
        XCTAssertThrowsError(try AppId("aaa_"))
        XCTAssertThrowsError(try AppId("aaaaa"))
    }
    
    func test_app_id_valid() {
        XCTAssertNoThrow(try AppId("aaaa"))
        XCTAssertNoThrow(try AppId("aaaA"))
        XCTAssertNoThrow(try AppId("aaa1"))
    }

}
