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
			self.newState(state: state)
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
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> Observable<T> {
		return map { $0[keyPath: keyPath] }
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Store.State == Observer.Element {
		var subscriber: RxStoreSubscriber<Store.State>? = RxStoreSubscriber()
		let disposable1 = subscriber?.subject.subscribe(observer) ?? Disposables.create()
		base.subscribe(subscriber!)
		let disposable2 = Disposables.create {
			subscriber = nil
		}
		return Disposables.create(disposable1, disposable2)
	}
	
}

extension RxStore where Store: DispatchingStoreType {
	
	public var actions: Observable<Action> {
		Observable.create { observer in
			var subscriber: RxStoreSubscriber<Action>? = RxStoreSubscriber()
			let disposable1 = subscriber?.subject.subscribe(observer) ?? Disposables.create()
			base.observeActions(subscriber!)
			let disposable2 = Disposables.create {
				subscriber = nil
			}
			return Disposables.create(disposable1, disposable2)
		}
	}
	
}

fileprivate final class RxStoreSubscriber<Element>: StoreSubscriber {
	let subject = PublishSubject<Element>()
	
	public func newState(state: Element) {
		subject.onNext(state)
	}
	
}

extension Reactive where Base: ViewProtocol {
	
	public var events: Observable<Base.Events> {
		Observable.merge(base.events())
	}
	
}

extension ReducerDisconnecter: Disposable {
	
	public func dispose() {
		disconnect()
	}
	
}

public func =>><V: ViewProtocol, O: ObservableConvertibleType>(_ lhs: O, _ rhs: Reactive<V>?) -> Disposable where O.Element == V.Properties, V.Properties: Equatable {
	rhs?.base.bind(lhs.asObservable().distinctUntilChanged()) ?? Disposables.create()
}

public func =>><Element, O: ObserverType>(_ lhs: StateDriver<Element>, _ rhs: O?) -> Disposable where O.Element == Element?, Element: Equatable {
	guard let rhs = rhs else { return Disposables.create() }
	return lhs.skipEqual() => rhs
}
