//
//  SubStore.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation

final class Substore<ParentState: StateType, State: StateType>: Store<State> {
	
	let parent: Store<ParentState>
	let lens: Lens<ParentState, State>
	override var state: State {
		lens.get(parent.state)
	}
	
	init(store: Store<ParentState>, lens: Lens<ParentState, State>) {
		parent = store
		self.lens = lens
		super.init(state: lens.get(store.state), middleware: [], automaticallySkipsRepeats: true)
	}
	
	override func _defaultDispatch(action: Action) {
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
