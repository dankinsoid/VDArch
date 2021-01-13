//
//  VDArchTests.swift
//  
//
//  Created by Данил Войдилов on 12.01.2021.
//

import XCTest
@testable import VDArch

final class VDArchTests: XCTestCase {
	
	func testExample() {
		var state = State()
		state.isLoading = true
		let json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(state), options: .allowFragments) as! [String: Any]
		XCTAssert(json["isLoading"] as? Bool == false)
		XCTAssert(json["isAnimating"] as? Bool == false)
	}
	
	static var allTests = [
		 ("testExample", testExample),
 	]
	
}

struct State: StateType, Codable, Equatable {
	var substate = SubState()
	var double = 2.4
	var bool = true
	@NonCacheable var isLoading = false
	@NonCacheable(false) var isAnimating = true
}

struct SubState: StateType, Codable, Equatable {
	var value = 0
	var sub = SubSubState()
}

struct SubSubState: StateType, Codable, Equatable {
	var string = "string"
}
