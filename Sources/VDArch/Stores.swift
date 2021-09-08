//
//  File.swift
//  
//
//  Created by Данил Войдилов on 14.01.2021.
//

import Foundation

open class Stores<A: Equatable, B: Equatable>: Store<UnionState<A, B>> {
	public let store1: Store<A>
	public let store2: Store<B>
	override public var state: UnionState<A, B> {
		UnionState(store1.state, store2.state)
	}
	
	public init(_ store1: Store<A>, _ store2: Store<B>, middleware: [Middleware<UnionState<A, B>>] = []) {
		self.store1 = store1
		self.store2 = store2
		super.init(state: UnionState(store1.state, store2.state), middleware: middleware)
	}
	
	public convenience init(state1: A, state2: B, reducer: @escaping Reducer<State>, middleware: [Middleware<UnionState<A, B>>] = []) {
		self.init(
			Store(state: state1),
			Store(state: state2),
			middleware: middleware
		)
		connect(reducer: reducer)
	}
	
	override func defaultDispatch(action: Action, completion: ((State) -> Void)?) {
		DoubleCallback<Void> {
            self.notify(action: action)
			completion?(self.state)
		}.execute(
			{ c in store1.dispatch(action, completion: { _ in c(()) }) },
			{ c in store2.dispatch(action, completion: { _ in c(()) }) }
		)
	}
	
	@discardableResult
	override open func connect(reducer: @escaping Reducer<UnionState<A, B>>) -> StoreUnsubscriber {
		let def = state
		let first = store1.connect {[weak self] action, state in
            var new = self.map { UnionState(state, $0.store2.state)} ?? def
            let result = reducer(action, &new)
            state = new.a
            return result
		}
		let second = store2.connect {[weak self] action, state in
            var new = self.map { UnionState($0.store1.state, state)} ?? def
            let result = reducer(action, &new)
            state = new.b
            return result
		}
		return StoreUnsubscriber {
			first.unsubscribe()
			second.unsubscribe()
		}
	}
	
	override func _subscribe<S: StoreSubscriber>(_ subscriber: S, sendCurrent: Bool) -> StoreUnsubscriber where State == S.StoreSubscriberStateType {
		let def = state
		let unsubscribe1 = store1._subscribe(
			subscriber.map {[weak self] a in
				self.map { UnionState(a, $0.store2.state) } ?? def
			},
			sendCurrent: false
		)
		let unsubscribe2 = store2._subscribe(
			subscriber.map {[weak self] b in
				self.map { UnionState($0.store1.state, b) } ?? def
			},
			sendCurrent: sendCurrent
		)
		return StoreUnsubscriber {
			unsubscribe1.unsubscribe()
			unsubscribe2.unsubscribe()
		}
	}

	override open func unsubscribe(_ subscriber: AnyStoreSubscriber) {
		super.unsubscribe(subscriber)
		store1.unsubscribe(subscriber)
		store2.unsubscribe(subscriber)
	}
}
