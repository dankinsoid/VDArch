import XCTest
import RxSwift
import RxOperators
@testable import VDArch

final class VDArchTests: XCTestCase {
	
	func testExample() {
		var state = State()
		state.isLoading = true
		let json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(state), options: .allowFragments) as! [String: Any]
		XCTAssert(json["isLoading"] as? Bool == false)
		XCTAssert(json["isAnimating"] as? Bool == false)
	}
	
	func testStores() {
		let expectation1 = expectation(description: "1")
		let expectation2 = expectation(description: "2")
		
		let store1 = Store(state: State())
		let store2 = Store(state: State2(), queue: .main)
		let stores = Stores(store1, store2)
		let subscriber = Subscriber<UnionState<State, State2>>()
		_ = stores.rx => subscriber
		store1.dispatch(EmptyAction()) { _ in expectation1.fulfill() }
		stores.dispatch(EmptyAction()) { _ in expectation2.fulfill() }
		waitForExpectations(timeout: 6, handler: nil)
		let expected = 1
		XCTAssert(subscriber.count == expected, "expected \(expected), got: \(subscriber.count)")
	}
	
	static var allTests = [
		("testExample", testExample),
		("testStores", testStores)
 	]
	
	private final class Subscriber<State: StateType>: StoreSubscriber, ObserverType {
		var count = 0
		
		func newState(state: State, oldState: State?) {
			count += 1
		}
		
		func on(_ event: Event<State>) {
			if case .next(let state) = event {
				newState(state: state, oldState: nil)
			}
		}
		
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
