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

open class Store<State: StateType>: ConnectableStoreType {
	
	typealias SubscriptionType = SubscriptionBox<State>
	
	private(set) open var state: State {
		didSet {
			subscriptions.forEach {
				if $0.subscriber == nil {
					subscriptions.remove($0)
				} else {
					$0.newValues(oldState: oldValue, newState: state)
				}
			}
		}
	}
	
	private(set) open lazy var dispatchFunction: DispatchFunction! = createDispatchFunction()
	
	private var subscriptions: Set<SubscriptionType> = []
	private var reducers: [UUID: Reducer<State>] = [:]
	private var ids: [UUID] = []
	private let lock = NSRecursiveLock()
	
	@Synchronized private var isDispatching = false
	
	/// Indicates if new subscriptions attempt to apply `skipRepeats`
	/// by default.
	fileprivate let subscriptionsAutomaticallySkipRepeats: Bool
	
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
	/// - parameter automaticallySkipsRepeats: If `true`, the store will attempt
	///   to skip idempotent state updates when a subscriber's state type
	///   implements `Equatable`. Defaults to `true`.
	public init(
		reducer: @escaping Reducer<State>,
		state: State,
		middleware: [Middleware<State>] = [],
		automaticallySkipsRepeats: Bool = true
	) {
		self.subscriptionsAutomaticallySkipRepeats = automaticallySkipsRepeats
		self.reducers = [UUID(): reducer]
		self.middleware = middleware
		self.state = state
	}
	
	public init(
		state: State,
		middleware: [Middleware<State>] = [],
		automaticallySkipsRepeats: Bool = true
	) {
		self.subscriptionsAutomaticallySkipRepeats = automaticallySkipsRepeats
		self.middleware = middleware
		self.state = state
	}
	
	private func createDispatchFunction() -> DispatchFunction! {
		// Wrap the dispatch function with all middlewares
		return middleware
			.reversed()
			.reduce(
				{ [unowned self] action in
					self._defaultDispatch(action: action) },
				{ dispatchFunction, middleware in
					// If the store get's deinitialized before the middleware is complete; drop
					// the action without dispatching.
					let dispatch: (Action) -> Void = { [weak self] in self?.dispatch($0) }
					let getState = { [weak self] in self?.state }
					return middleware(dispatch, getState)(dispatchFunction)
				})
	}
	
	private func _subscribe<SelectedState, S: StoreSubscriber>(
		_ subscriber: S, originalSubscription: Subscription<State>,
		transformedSubscription: Subscription<SelectedState>?)
	where S.StoreSubscriberStateType == SelectedState
	{
		let subscriptionBox = self.subscriptionBox(
			originalSubscription: originalSubscription,
			transformedSubscription: transformedSubscription,
			subscriber: subscriber
		)
		
		subscriptions.update(with: subscriptionBox)
		
		if let state = self.state {
			originalSubscription.newValues(oldState: nil, newState: state)
		}
	}
	
	open func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.StoreSubscriberStateType == State {
		_subscribe(subscriber, originalSubscription: Subscription(), transformedSubscription: nil)
	}
	
	open func subscribe<S: StoreSubscriber>(
		_ subscriber: S, transform: ((Subscription<State>) -> Subscription<S.StoreSubscriberStateType>)
	) {
		// Create a subscription for the new subscriber.
		let originalSubscription = Subscription<State>()
		// Call the optional transformation closure. This allows callers to modify
		// the subscription, e.g. in order to subselect parts of the store's state.
		let transformedSubscription = transform(originalSubscription)
		
		_subscribe(subscriber, originalSubscription: originalSubscription,
							 transformedSubscription: transformedSubscription)
	}
	
	func subscriptionBox<T>(
		originalSubscription: Subscription<State>,
		transformedSubscription: Subscription<T>?,
		subscriber: AnyStoreSubscriber
	) -> SubscriptionBox<State> {
		
		return SubscriptionBox(
			originalSubscription: originalSubscription,
			transformedSubscription: transformedSubscription,
			subscriber: subscriber
		)
	}
	
	open func unsubscribe(_ subscriber: AnyStoreSubscriber) {
		#if swift(>=5.0)
		if let index = subscriptions.firstIndex(where: { return $0.subscriber === subscriber }) {
			subscriptions.remove(at: index)
		}
		#else
		if let index = subscriptions.index(where: { return $0.subscriber === subscriber }) {
			subscriptions.remove(at: index)
		}
		#endif
	}
	
	// swiftlint:disable:next identifier_name
	open func _defaultDispatch(action: Action) {
		guard !isDispatching else {
			fatalError(
				"VDArch:ConcurrentMutationError- Action has been dispatched while" +
					" a previous action is action is being processed. A reducer" +
					" is dispatching an action, or VDArch is used in a concurrent context" +
					" (e.g. from multiple threads)."
			)
		}
		
		isDispatching = true
		let newState = reduce(action: action, state: state)
		isDispatching = false
		
		state = newState
	}
	
	open func dispatch(_ action: Action) {
		dispatchFunction(action)
	}
	
	@discardableResult
	open func connect(reducer: @escaping Reducer<State>) -> ReducerDisconnecter {
		let id = UUID()
		lock.protect {
			self.reducers[id] = reducer
			self.ids.append(id)
		}
		return ReducerDisconnecter {[weak self] in
			self?.disconnect(id: id)
		}
	}
	
	open func substore<Substate: StateType>(lens: Lens<State, Substate>) -> Store<Substate> {
		let substore = Substore(store: self, lens: lens)
		return substore
	}
	
	open func substore<Substate: StateType>(_ keyPath: WritableKeyPath<State, Substate>) -> Store<Substate> {
		Substore(store: self, lens: Lens(at: keyPath))
	}
	
	private func reduce(action: Action, state: State?) -> State {
		var result: State = state ?? self.state
		ids.forEach {
			lock.lock()
			guard let reducer = reducers[$0] else {
				lock.unlock()
				return
			}
			lock.unlock()
			result = reducer(action, result)
		}
		return result
	}
	
	private func disconnect(id: UUID) {
		lock.lock()
		reducers[id] = nil
		if let i = ids.lastIndex(of: id) {
			ids.remove(at: i)
		}
		lock.unlock()
	}
}

// MARK: Skip Repeats for Equatable States

extension Store {
	open func subscribe<SelectedState: Equatable, S: StoreSubscriber>(
		_ subscriber: S, transform: ((Subscription<State>) -> Subscription<SelectedState>)?
	) where S.StoreSubscriberStateType == SelectedState
	{
		let originalSubscription = Subscription<State>()
		
		var transformedSubscription = transform?(originalSubscription)
		if subscriptionsAutomaticallySkipRepeats {
			transformedSubscription = transformedSubscription?.skipRepeats()
		}
		_subscribe(subscriber, originalSubscription: originalSubscription,
							 transformedSubscription: transformedSubscription)
	}
}

extension Store where State: Equatable {
	open func subscribe<S: StoreSubscriber>(_ subscriber: S)
	where S.StoreSubscriberStateType == State {
		guard subscriptionsAutomaticallySkipRepeats else {
			subscribe(subscriber, transform: nil)
			return
		}
		subscribe(subscriber, transform: { $0.skipRepeats() })
	}
}
