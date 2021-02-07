//
//  Rx++.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxOperators

extension StoreSubscriber {
	
	public func asObserver() -> AnyObserver<StoreSubscriberStateType> {
		AnyObserver {
			guard case .next(let state) = $0 else { return }
			self.newState(state: state, oldState: nil)
		}
	}
	
}

extension StoreType {
	public var rx: RxStore<Self> { RxStore(self) }
}

@dynamicMemberLookup
public struct RxStore<Store: StoreType>: ObservableType {
	public typealias Element = Store.State
	public let base: Store
	
	public var dispatcher: AnyObserver<Action> {
		AnyObserver {[base] in
			guard case .next(let action) = $0 else { return }
			base.dispatch(action)
		}
	}
	
	public init(_ store: Store) {
		base = store
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: {_, _ in true }, map: { $0[keyPath: keyPath] })
	}
	
	public subscript<T: Equatable>(dynamicMember keyPath: KeyPath<Element, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: !=, map: { $0[keyPath: keyPath] })
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Store.State == Observer.Element {
		let subscriber = RxStoreSubscriber<Store.State> { new, _ in
			observer.onNext(new)
		}
		return Disposables.create(with: base.subscribe(subscriber).unsubscribe)
	}
	
}

@dynamicMemberLookup
public struct StoreObservable<Store: StoreType, Element>: ObservableType {
	public let base: Store
	let condition: (Element, Element?) -> Bool
	let map: (Store.State) -> Element
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: {_, _ in true}, map: {[map] in map($0)[keyPath: keyPath] })
	}
	
	public subscript<T: Equatable>(dynamicMember keyPath: KeyPath<Element, T>) -> StoreObservable<Store, T> {
		StoreObservable<Store, T>(base: base, condition: !=, map: {[map] in map($0)[keyPath: keyPath] })
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Element == Observer.Element {
		let subscriber = RxStoreSubscriber<Store.State> {[map] _new, _old in
			let new = map(_new)
			let old = _old.map(map)
			if condition(new, old) {
				observer.onNext(new)
			}
		}
		return Disposables.create(with: base.subscribe(subscriber).unsubscribe)
	}
	
}

extension RxStore where Store: DispatchingStoreType {
	
	public var actions: Observable<Action> {
		Observable.create { observer in
			let subscriber = RxStoreSubscriber<Action> { new, old in
				observer.onNext(new)
			}
			return Disposables.create(with:  base.observeActions(subscriber).unsubscribe)
		}
	}
	
}

fileprivate final class RxStoreSubscriber<Element>: StoreSubscriber {
	let observer: (Element, Element?) -> Void
	
	init(observer: @escaping (Element, Element?) -> Void) {
		self.observer = observer
	}
	
	func newState(state: Element, oldState: Element?) {
		observer(state, oldState)
	}
}

extension Reactive where Base: ViewProtocol {
	
	public var events: Observable<Base.Events> {
		Observable.merge(base.events())
	}
	
}

extension StoreUnsubscriber: Disposable {
	
	public func dispose() {
		unsubscribe()
	}
	
}

public func =>><V: ViewProtocol, O: ObservableConvertibleType>(_ lhs: O, _ rhs: Reactive<V>?) -> Disposable where O.Element == V.Properties, V.Properties: Equatable {
	rhs?.base.bind(lhs.asObservable().distinctUntilChanged()) ?? Disposables.create()
}

public func =>><Element, O: ObserverType>(_ lhs: StateDriver<Element>, _ rhs: O?) -> Disposable where O.Element == Element?, Element: Equatable {
	guard let rhs = rhs else { return Disposables.create() }
	return lhs.skipEqual() => rhs
}
