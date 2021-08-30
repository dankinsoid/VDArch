//
//  Reducers.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine

public protocol ReducerBaseModule {
	associatedtype State: Equatable
	func reduceAny(action: Action, state: inout State) -> Void
}

extension ReducerBaseModule {
	
	public func reduce(actions: Action..., state: inout State) -> Void {
		var state = state
		for action in actions {
			reduceAny(action: action, state: &state)
		}
	}
}

public protocol ReducerModule: ReducerBaseModule {
	associatedtype Event: Action
	func reduce(action: Event, state: inout State) -> Void
}

extension ReducerModule where State == Never {
    public func reduce(action: Event, state: inout State) -> Void {}
}

extension ReducerModule {
	
	public func reduceAny(action: Action, state: inout State) -> Void {
		guard let event = action as? Event else { return }
		reduce(action: event, state: &state)
	}
	
	public func asReducer() -> Reducer<State> {
		reduceAny
	}
}

extension ReducerBaseModule {
	
    public func asGlobal<S: Equatable>(with lens: Lens<S, State>) -> Reducer<S> {
		return { action, state in
            var newState = lens.get(state)
            self.reduceAny(action: action, state: &newState)
            state = lens.set(state, newState)
		}
	}
}
