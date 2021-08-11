//
//  Reducers.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine

public protocol ReducerConvertible {
	associatedtype ReducerStateType
	func asReducer() -> Reducer<ReducerStateType>
}

public protocol ReducerBaseModule: ReducerConvertible {
	associatedtype State: Equatable
	func reduceAny(action: Action, state: State) -> State
}

extension ReducerBaseModule {
	
	public func reduce(actions: Action..., state: State) -> State {
		var state = state
		for action in actions {
			state = reduceAny(action: action, state: state)
		}
		return state
	}
	
	public func asReducer() -> Reducer<State> {
		reduceAny
	}
	
}

public protocol ReducerModule: ReducerConvertible {
	associatedtype Event: Action
	associatedtype State: Equatable
	func reduce(action: Event, state: State) -> State
}

extension ReducerModule {
	
	public func reduceAny(action: Action, state: State) -> State {
		guard let event = action as? Event else { return state }
		return reduce(action: event, state: state)
	}
	
	public func asReducer() -> Reducer<State> {
		reduceAny
	}
	
}

extension ReducerConvertible {
	
	public func asGlobal<State>(with lens: Lens<State, ReducerStateType>) -> Reducer<State> {
		return { action, state in
			return lens.set(state, self.asReducer()(action, lens.get(state)))
		}
	}
	
}
