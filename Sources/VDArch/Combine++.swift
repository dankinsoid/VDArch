//
//  Rx++.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine
import CombineCocoa
import CombineOperators

@available(iOS 13.0, *)
extension StoreSubscriber {
	
	public func asSubscriber() -> AnySubscriber<StoreSubscriberStateType, Never> {
		AnySubscriber {
			$0.request(.unlimited)
		} receiveValue: { state in
			self.newState(state: state, oldState: nil)
			return .unlimited
		} receiveCompletion: { _ in }
	}
}

@available(iOS 13.0, *)
extension StoreType {
	public var cb: CombineStore<Self> { CombineStore(self) }
}

@available(iOS 13.0, *)
@dynamicMemberLookup
public struct CombineStore<Store: StoreType>: Publisher {
	
	public typealias Output = Store.State
	public typealias Failure = Never
	public let base: Store
	let willSet: Bool
	public var willChange: CombineStore<Store> {
		CombineStore(base, willSet: true)
	}
	
	public var dispatcher: AnySubscriber<Action, Never> {
		AnySubscriber {
			$0.request(.unlimited)
		} receiveValue: {[base] in
			base.dispatch($0)
			return .unlimited
		} receiveCompletion: { _ in }
	}
	
	public var onChange: StoreOnChangePublisher<Store, Store.State> {
		StoreOnChangePublisher(base: base, condition: !=, map: { $0 }, willSet: false)
	}
	
	public init(_ store: Store) {
		base = store
		self.willSet = false
	}
	
	init(_ store: Store, willSet: Bool) {
		base = store
		self.willSet = willSet
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StorePublisher<Store, T> {
		StorePublisher<Store, T>(base: base, condition: {_, _ in true }, map: { $0[keyPath: keyPath] }, willSet: willSet)
	}
	
	public subscript<T: Equatable>(dynamicMember keyPath: KeyPath<Output, T>) -> StorePublisher<Store, T> {
		StorePublisher<Store, T>(base: base, condition: !=, map: { $0[keyPath: keyPath] }, willSet: willSet)
	}
    
    public func map<T: Equatable>(_ map: @escaping (Store.State) -> T) -> AnyPublisher<T, Never> {
        onChange
            .map { ($0.0.map(map), map($0.1)) }
            .filter { $0.0 != $0.1 && $0.0 != nil }
            .map { $0.1 }
            .any()
    }
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Store.State == S.Input {
		subscriber.receive(
			subscription: CombineStoreSubscription(
				subscriber: subscriber.mapSubscriber { $0.1 },
				store: base,
				willSet: willSet,
				condition: !=, map: { $0 }
			)
		)
	}
}

@available(iOS 13.0, *)
@dynamicMemberLookup
public struct StorePublisher<Store: StoreType, Output>: Publisher {
	public typealias Failure = Never
	public let base: Store
	let condition: (Output, Output?) -> Bool
	let map: (Store.State) -> Output
	let willSet: Bool
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StorePublisher<Store, T> {
		StorePublisher<Store, T>(base: base, condition: {_, _ in true}, map: {[map] in map($0)[keyPath: keyPath] }, willSet: willSet)
	}
	
	public subscript<T: Equatable>(dynamicMember keyPath: KeyPath<Output, T>) -> StorePublisher<Store, T> {
		StorePublisher<Store, T>(base: base, condition: !=, map: {[map] in map($0)[keyPath: keyPath] }, willSet: willSet)
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
		subscriber
			.receive(
			subscription: CombineStoreSubscription(
				subscriber: subscriber.mapSubscriber { $0.1 },
				store: base,
				willSet: willSet,
				condition: condition,
				map: map
			)
		)
	}
}

extension StorePublisher where Output: Equatable {
	
	public var onChange: StoreOnChangePublisher<Store, Output> {
		StoreOnChangePublisher(base: base, condition: !=, map: map, willSet: willSet)
	}
}

@available(iOS 13.0, *)
@dynamicMemberLookup
public struct StoreOnChangePublisher<Store: StoreType, Value>: Publisher {
	public typealias Failure = Never
	public typealias Output = (Value?, Value)
	public let base: Store
	let condition: (Value, Value?) -> Bool
	let map: (Store.State) -> Value
	let willSet: Bool
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> StoreOnChangePublisher<Store, T> {
		StoreOnChangePublisher<Store, T>(
			base: base,
			condition: {_, _ in true},
			map: {[map] in map($0)[keyPath: keyPath] },
			willSet: willSet
		)
	}
	
	public subscript<T: Equatable>(dynamicMember keyPath: KeyPath<Value, T>) -> StoreOnChangePublisher<Store, T> {
		StoreOnChangePublisher<Store, T>(
			base: base,
			condition: !=,
			map: {[map] in map($0)[keyPath: keyPath] },
			willSet: willSet
		)
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
		subscriber
			.receive(
				subscription: CombineStoreSubscription(
					subscriber: subscriber,
					store: base,
					willSet: willSet,
					condition: condition,
					map: map
				)
			)
	}
}

@available(iOS 13.0, *)
extension CombineStore where Store: DispatchingStoreType {
	
	public var actions: AnyPublisher<Action, Never> {
		Publishers.Create { observer in
			let subscriber = CombineStoreSubscriber<Action>(willSet: false) { new, old in
				_ = observer.receive(new)
			}
			return AnyCancellable(base.observeActions(subscriber).unsubscribe)
		}
		.any()
	}
}

@available(iOS 13.0, *)
fileprivate final class CombineStoreSubscriber<Element>: StoreSubscriber {
	let observer: (Element, Element?) -> Void
	let willSet: Bool
	
	init(willSet: Bool, observer: @escaping (Element, Element?) -> Void) {
		self.willSet = willSet
		self.observer = observer
	}
	
	func willSetState(state: Element, oldState: Element?) {
		guard willSet else { return }
		observer(state, oldState)
	}
	
	func newState(state: Element, oldState: Element?) {
		guard !willSet else { return }
		observer(state, oldState)
	}
}

@available(iOS 13.0, *)
fileprivate final class CombineStoreSubscription<Store: StoreType, Input, S: Subscriber>: Subscription where S.Input == (Input?, Input) {
	let subscriber: S
	var store: Store?
	var unsubscriber: StoreUnsubscriber?
	let condition: (Input, Input?) -> Bool
	let map: (Store.State) -> Input
	let willSet: Bool
	
	init(subscriber: S, store: Store, willSet: Bool, condition: @escaping (Input, Input?) -> Bool, map: @escaping (Store.State) -> Input) {
		self.subscriber = subscriber
		self.store = store
		self.condition = condition
		self.map = map
		self.willSet = willSet
	}
	
	func request(_ demand: Subscribers.Demand) {
		unsubscriber?.unsubscribe()
		unsubscriber = store?.subscribe(CombineStoreSubscriber(willSet: willSet) {[self] _new, _old in
			let new = map(_new)
			let old = _old.map(map)
			if condition(new, old) {
				_ = subscriber.receive((old, new))
			}
		})
		store = nil
	}
	
	func cancel() {
		unsubscriber?.unsubscribe()
		unsubscriber = nil
		store = nil
	}
}

@available(iOS 13.0, *)
extension Reactive where Base: ViewProtocol {
	public var events: AnyPublisher<Base.Events, Never> {
		base.events
	}
}

@available(iOS 13.0, *)
extension StoreUnsubscriber: Cancellable {
	public func cancel() {
		unsubscribe()
	}
}

extension Store: ObservableObject {
	public typealias ObjectWillChangePublisher = CombineStore<Store>
	
	public var objectWillChange: CombineStore<Store> {
		cb
	}
}

@available(iOS 13.0, *)
public func =>><V: ViewProtocol, O: Publisher>(_ lhs: O, _ rhs: Reactive<V>?) where O.Output == V.Properties, V.Properties: Equatable {
	rhs?.base.bind(lhs.removeDuplicates())
}

@available(iOS 13.0, *)
public func =>><Element, O: Subscriber>(_ lhs: StateSignal<Element>, _ rhs: O?) where O.Input == Element?, Element: Equatable {
	guard let rhs = rhs else { return }
	lhs.skipEqual() => rhs
}
