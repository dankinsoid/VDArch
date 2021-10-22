//
//  VDArchTests.swift
//  
//
//  Created by Данил Войдилов on 12.01.2021.
//

import XCTest
import Combine
import SwiftUI
@testable import CombineOperators
@testable import VDArch

@available(iOS 13.0, *)
final class VDArchTests: XCTestCase {
	
	func testExample() {
//		state.isLoading = true
//		let json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(state), options: .allowFragments) as! [String: Any]
//		XCTAssert(json["isLoading"] as? Bool == false)
//		XCTAssert(json["isAnimating"] as? Bool == false)
	}
	
	func testStores() {
//		let expectations = (0..<3).map { expectation(description: "\($0)") }
//		var count = 0
//		let store = Store(reducer: { _, state in
//            state.double = .random(in: 0...10)
//            return .empty()
//		}, state: State())
//		var cancellable = CancellablePublisher()
//		store.cb.prefix(untilOutputFrom: cancellable).subscribe { _ in
//			expectations[count].fulfill()
//			count += 1
//		}
//		store.dispatch(EmptyAction())
//		store.dispatch(EmptyAction())
		
//		waitForExpectations(timeout: 6, handler: nil)
//		XCTAssert(count == 3, "\(count)")
	}
	
	static var allTests = [
		("testExample", testExample),
		("testStores", testStores)
 	]
	
	@available(iOS 13.0, *)
	private final class _Subscriber<State: Equatable>: StoreSubscriber, Subscriber {
		
		typealias Input = State
		typealias Failure = Never
		
		var count = 0
		
		func newState(state: State, oldState: State?) {
			count += 1
		}
		
		func willSetState(state: State, oldState: State?) {}
		
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
