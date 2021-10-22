//
//  Store.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

/**
 This class is the default implementation of the `StoreType` protocol. You will use this store in most
 of your applications. You shouldn't need to implement your own store.
 You initialize the store with a reducer and an initial application state. If your app has multiple
 reducers you can combine them by initializng a `MainReducer` with all of your reducers as an
 argument.
 */

import Foundation
import Combine

@dynamicMemberLookup
open class Store<State: Equatable>: ConnectableStoreType {
	
	private(set) open var state: State {
		willSet {
			notify(newValue: newValue)
		}
		didSet {
			notify(oldValue: oldValue)
		}
	}
	
	private(set) open lazy var dispatchFunction: (Action, @escaping (State) -> Void) -> Void = createDispatchFunction()
	
	private var subscriptions: Set<StoreSubscriberHashable> = []
	private var actionSubscriptions: Set<StoreSubscriberHashable> = []
	private var reducers: [UUID: Reducer<State>] = [:]
	private var ids: [UUID] = []
	private let lock = NSRecursiveLock()
	public let queue: DispatchQueue
	
	public var middleware: [Middleware<State>] {
		didSet {
			dispatchFunction = createDispatchFunction()
		}
	}
	
	/// Initializes the store with a reducer, an initial state and a list of middleware.
	///
	/// Middleware is applied in the order in which it is passed into this constructor.
	///
	/// - parameter reducer: Main reducer that processes incoming actions.
	/// - parameter state: Initial state, if any. Can be `nil` and will be
	///   provided by the reducer in that case.
	/// - parameter middleware: Ordered list of action pre-processors, acting
	///   before the root reducer.
	/// - parameter queue: serial DispatchQueue for dispatching.
	/// - parameter automaticallySkipsRepeats: If `true`, the store will attempt
	///   to skip idempotent state updates when a subscriber's state type
	///   implements `Equatable`. Defaults to `true`.
	public convenience init(
		reducer: @escaping Reducer<State>,
		state: State,
		middleware: [Middleware<State>] = [],
		queue: DispatchQueue = .store
	) {
		self.init(state: state, middleware: middleware, queue: queue)
		_ = self.connect(reducer: reducer)
	}
	
	public init(
		state: State,
		middleware: [Middleware<State>] = [],
		queue: DispatchQueue = .store
	) {
		self.middleware = middleware
		self.queue = queue
		self.state = state
	}
	
	private func createDispatchFunction() -> (Action, @escaping (State) -> Void) -> Void {
		// Wrap the dispatch function with all middlewares
		return middleware
			.reversed()
			.reduce(
				{ [unowned self] action, completion in
					self.defaultDispatch(action: action, completion: completion) },
				{ dispatchFunction, middleware in
					// If the store get's deinitialized before the middleware is complete; drop
					// the action without dispatching.
					let dispatch: (Action) -> Void = { [weak self] in self?.dispatch($0) }
					let getState = { [weak self] in self?.state }
					return { action, completion in middleware(dispatch, getState)({ dispatchFunction($0, completion) })(action) }
				})
	}
	
	func _subscribe<S: StoreSubscriber>(_ subscriber: S, sendCurrent: Bool) -> StoreUnsubscriber where State == S.StoreSubscriberStateType {
		subscriptions.update(with: StoreSubscriberHashable(subscriber))
		if sendCurrent {
			subscriber.newState(state: state, oldState: nil)
		}
		return StoreUnsubscriber {[weak self] in
			self?.unsubscribe(subscriber)
		}
	}
	
	@discardableResult
	open func observeActions<S: StoreSubscriber>(_ subscriber: S) -> StoreUnsubscriber where S.StoreSubscriberStateType == Action {
		_observeActions(subscriber)
	}
	
	@discardableResult
	open func observeActions<S: StoreSubscriber>(_ subscriber: S) -> StoreUnsubscriber where S.StoreSubscriberStateType: Action {
		_observeActions(subscriber)
	}
	
	func _observeActions(_ subscriber: AnyStoreSubscriber) -> StoreUnsubscriber {
		actionSubscriptions.update(with: StoreSubscriberHashable(subscriber))
		return StoreUnsubscriber {[weak self] in
			self?.unsubscribe(subscriber)
		}
	}
	
	@discardableResult
	open func subscribe<S: StoreSubscriber>(_ subscriber: S) -> StoreUnsubscriber where S.StoreSubscriberStateType == State {
		_subscribe(subscriber, sendCurrent: true)
	}
	
	open func unsubscribe(_ subscriber: AnyStoreSubscriber) {
		let hashable = StoreSubscriberHashable(subscriber)
		subscriptions.remove(hashable)
		actionSubscriptions.remove(hashable)
	}
	
	func defaultDispatch(action: Action, completion: ((State) -> Void)?) {
		queue.async {[self] in
			reduce(action: action)
			notify(action: action)
			completion?(self.state)
		}
	}
	
	final func notify(action: Action) {
		actionSubscriptions.forEach {
			$0.newState(action, nil)
		}
	}
	
	final func notify(newValue: State) {
		guard state != newValue else { return }
		subscriptions.forEach {
			$0.willSetState(newValue, state)
		}
	}
	
	final func notify(oldValue: State) {
		guard state != oldValue else { return }
		subscriptions.forEach {
			$0.newState(state, oldValue)
		}
	}
	
	open func dispatch(_ action: Action) {
		self.dispatch(action, completion: {_ in})
	}
	
	open func dispatch(_ action: Action, completion: @escaping (State) -> Void) {
		self.dispatchFunction(action, completion)
	}
	
	@discardableResult
	open func connect(reducer: @escaping Reducer<State>) -> StoreUnsubscriber {
		let id = UUID()
		lock.protect {
			self.reducers[id] = reducer
			self.ids.append(id)
		}
		return StoreUnsubscriber {[weak self] in
			self?.unsubscribe(id: id)
		}
	}
	
	open subscript<Substate: Equatable>(dynamicMember keyPath: WritableKeyPath<State, Substate>) -> Store<Substate> {
		substore(keyPath)
	}
	
	open func substore<Substate: Equatable>(lens: Lens<State, Substate>) -> Store<Substate> {
		Substore(store: self, lens: lens)
	}
	
	open func substore<Substate: Equatable>(_ keyPath: WritableKeyPath<State, Substate>) -> Store<Substate> {
		substore(lens: Lens(at: keyPath))
	}
	
	private func reduce(action: Action) {
		var actions: [AnyPublisher<Action, Never>] = []
		ids.forEach {
			lock.lock()
			guard let reducer = reducers[$0] else {
				lock.unlock()
				return
			}
			lock.unlock()
			actions.append(reducer(action, &state))
		}
		Publishers.MergeMany(actions).subscribe {[weak self] in
			self?.dispatch($0)
		}
	}
	
	private func unsubscribe(id: UUID) {
		lock.lock()
		reducers[id] = nil
		if let i = ids.lastIndex(of: id) {
			ids.remove(at: i)
		}
		lock.unlock()
	}
}
