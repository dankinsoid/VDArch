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
	
	public var dispatcher: AnySubscriber<Action, Never> {
		AnySubscriber {
			$0.request(.unlimited)
		} receiveValue: {[base] in
			base.dispatch($0)
			return .unlimited
		} receiveCompletion: { _ in }
	}
	
	public init(_ store: Store) {
		base = store
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: {_, _ in true }, map: { $0[keyPath: keyPath] })
	}
	
	public subscript<T: Equatable>(dynamicMember keyPath: KeyPath<Output, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: !=, map: { $0[keyPath: keyPath] })
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Store.State == S.Input {
		subscriber.receive(subscription: CombineStoreSubscription(subscriber: subscriber, store: base, condition: !=, map: { $0 }))
	}
	
}

@available(iOS 13.0, *)
@dynamicMemberLookup
public struct StoreObservable<Store: StoreType, Output>: Publisher {
	public typealias Failure = Never
	public let base: Store
	let condition: (Output, Output?) -> Bool
	let map: (Store.State) -> Output
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: {_, _ in true}, map: {[map] in map($0)[keyPath: keyPath] })
	}
	
	public subscript<T: Equatable>(dynamicMember keyPath: KeyPath<Output, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: !=, map: {[map] in map($0)[keyPath: keyPath] })
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
		subscriber.receive(subscription: CombineStoreSubscription(subscriber: subscriber, store: base, condition: condition, map: map))
	}
	
}

@available(iOS 13.0, *)
extension CombineStore where Store: DispatchingStoreType {
	
	public var actions: AnyPublisher<Action, Never> {
		Publishers.Create { observer in
			let subscriber = CombineStoreSubscriber<Action> { new, old in
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
	
	init(observer: @escaping (Element, Element?) -> Void) {
		self.observer = observer
	}
	
	func newState(state: Element, oldState: Element?) {
		observer(state, oldState)
	}
}

@available(iOS 13.0, *)
fileprivate final class CombineStoreSubscription<Store: StoreType, S: Subscriber>: Subscription {
	let subscriber: S
	var store: Store?
	var unsubscriber: StoreUnsubscriber?
	let condition: (S.Input, S.Input?) -> Bool
	let map: (Store.State) -> S.Input
	
	init(subscriber: S, store: Store, condition: @escaping (S.Input, S.Input?) -> Bool, map: @escaping (Store.State) -> S.Input) {
		self.subscriber = subscriber
		self.store = store
		self.condition = condition
		self.map = map
	}
	
	func request(_ demand: Subscribers.Demand) {
		unsubscriber = store?.subscribe(CombineStoreSubscriber(observer: {[subscriber, map, condition] _new, _old in
			let new = map(_new)
			let old = _old.map(map)
			if condition(new, old) {
				_ = subscriber.receive(new)
			}
		}))
	}
	
	func cancel() {
		unsubscriber?.unsubscribe()
		unsubscriber = nil
		store = nil
	}
	
	deinit {
		cancel()
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

@available(iOS 13.0, *)
public func =>><V: ViewProtocol, O: Publisher>(_ lhs: O, _ rhs: Reactive<V>?) where O.Output == V.Properties, V.Properties: Equatable {
	rhs?.base.bind(lhs.removeDuplicates())
}

@available(iOS 13.0, *)
public func =>><Element, O: Subscriber>(_ lhs: StateDriver<Element>, _ rhs: O?) where O.Input == Element?, Element: Equatable {
	guard let rhs = rhs else { return }
	lhs.skipEqual() => rhs
}
