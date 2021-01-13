//
//  File.swift
//  
//
//  Created by Данил Войдилов on 13.01.2021.
//

import Foundation

final class ChildStore<ParentState: StateType, State: StateType>: Store<State> {
	
	let parent: Store<ParentState>
	var lens: Lens<ParentState, State> {
		Lens(
			get: {[state, weak self] _ in self?.state ?? state },
			set: {[weak self] parent, child in
				self?.set(state: child)
				return parent
			}
		)
	}
	
	init(store: Store<ParentState>, state: State, on queue: DispatchQueue) {
		parent = store
		super.init(state: state, middleware: [], queue: queue, automaticallySkipsRepeats: true)
	}
	
	override func defaultDispatch(action: Action) {
		super.defaultDispatch(action: action)
		parent.dispatch(action)
	}
	
	@discardableResult
	override func connect(reducer: @escaping Reducer<State>) -> ReducerDisconnecter {
		parent.connect(reducer: reducer, lens: lens)
	}
	
	override func unsubscribe(_ subscriber: AnyStoreSubscriber) {
		parent.unsubscribe(subscriber)
	}
	
	override func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.StoreSubscriberStateType == State {
		parent.subscribe(subscriber, transform: {[lens] in $0.select(lens.get) })
	}
	
	override func subscribe<S: StoreSubscriber>(
		_ subscriber: S,
		transform: ((Subscription<State>) -> Subscription<S.StoreSubscriberStateType>)
	) {
		parent.subscribe(subscriber) {[lens] in
			transform($0.select(lens.get))
		}
	}
	
}
