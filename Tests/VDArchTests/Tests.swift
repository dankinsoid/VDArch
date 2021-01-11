//
//  VDArchTests.swift
//  
//
//  Created by Данил Войдилов on 12.01.2021.
//

import VDArch
import XCTest

class VDArchTests: XCTestCase {
	
	func test() {
		let store = Store(state: State())
		let substore = store.substore(\.substate)
	}
	
}

struct State: StateType {
	var substate = SubState()
	var double = 2.4
	var bool = true
}

struct SubState: StateType {
	var value = 0
	var sub = SubSubState()
}

struct SubSubState: StateType {
	var string = "string"
}
