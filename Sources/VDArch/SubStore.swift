//
//  SubStore.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation

final class Substore<ParentState: Equatable, State: Equatable>: Store<State> {
	
	let parent: Store<ParentState>
	let lens: Lens<ParentState, State>
	override var state: State {
		lens.get(parent.state)
	}
	
	init(store: Store<ParentState>, lens: Lens<ParentState, State>) {
		parent = store
		self.lens = lens
		super.init(state: lens.get(store.state), middleware: [])
	}
	
	override func defaultDispatch(action: Action, completion: ((State) -> Void)?) {
		parent.dispatch(action, completion: { completion?(self.lens.get($0)) })
	}
	
	@discardableResult
	override func connect(reducer: @escaping Reducer<State>) -> StoreUnsubscriber {
		parent.connect(reducer: reducer, lens: lens)
	}
	
	override func unsubscribe(_ subscriber: AnyStoreSubscriber) {
		parent.unsubscribe(subscriber)
	}
	
	override func _observeActions(_ subscriber: AnyStoreSubscriber) -> StoreUnsubscriber {
		parent._observeActions(subscriber)
	}
	
	@discardableResult
	override func subscribe<S: StoreSubscriber>(_ subscriber: S) -> StoreUnsubscriber where S.StoreSubscriberStateType == State {
		parent.subscribe(
			subscriber.map {[lens] in
				lens.get($0)
			}
		)
	}
	
}
