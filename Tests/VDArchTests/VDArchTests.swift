//
//  VDArchTests.swift
//  
//
//  Created by Данил Войдилов on 12.01.2021.
//

import XCTest
import Combine
@testable import CombineOperators
@testable import VDArch

@available(iOS 13.0, *)
final class VDArchTests: XCTestCase {
	
	func testExample() {
		var state = State()
		state.isLoading = true
		let json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(state), options: .allowFragments) as! [String: Any]
		XCTAssert(json["isLoading"] as? Bool == false)
		XCTAssert(json["isAnimating"] as? Bool == false)
	}
	
	func testStores() {
		let expectations = (0..<3).map { expectation(description: "\($0)") }
		var count = 0
		let store = Store(reducer: { _, state in
			var result = state
			result.double = .random(in: 0...10)
			return result
		}, state: State())
		var cancellable = CancellablePublisher()
		store.cb.prefix(untilOutputFrom: cancellable).subscribe { _ in
			expectations[count].fulfill()
			count += 1
		}
		store.dispatch(EmptyAction())
		store.dispatch(EmptyAction())
		
		waitForExpectations(timeout: 6, handler: nil)
		XCTAssert(count == 3, "\(count)")
	}
	
	static var allTests = [
		("testExample", testExample),
		("testStores", testStores)
 	]
	
	@available(iOS 13.0, *)
	private final class _Subscriber<State: StateType>: StoreSubscriber, Subscriber {
		
		typealias Input = State
		typealias Failure = Never
		
		var count = 0
		
		func newState(state: State, oldState: State?) {
			count += 1
		}
		
		func receive(subscription: Subscription) {
			subscription.request(.unlimited)
		}
		
		func receive(_ input: State) -> Subscribers.Demand {
			newState(state: input, oldState: nil)
			return .unlimited
		}
		
		func receive(completion: Subscribers.Completion<Never>) {}
		
	}
	
}

struct State: StateType, Codable, Equatable {
	var substate = SubState()
	var double = 2.4
	var bool = true
	@NonCacheable(false) var isLoading = false
	@NonCacheable(false) var isAnimating = true
}

struct State2: StateType, Codable, Equatable {
	var double = 2.4
	var bool = true
}

struct SubState: StateType, Codable, Equatable {
	var value = 0
	var sub = SubSubState()
}

struct SubSubState: StateType, Codable, Equatable {
	var string = "string"
}
