//
//  Reducers.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import RxSwift

public protocol ReducerConvertible {
	associatedtype ReducerStateType
	func asReducer() -> Reducer<ReducerStateType>
}

public protocol ReducerBaseModule: ReducerConvertible {
	associatedtype State: Equatable
	func reduceAny(action: Action, state: State?) -> State
}

extension ReducerBaseModule {
	
	public func reduce(actions: Action..., state: State?) -> State? {
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
	var defaultState: State { get }
	func reduce(action: Event, state: State) -> State
}

extension ReducerModule {
	
	public func reduceAny(action: Action, state: State?) -> State {
		guard let event = action as? Event else { return state ?? defaultState }
		guard let state = state else { return defaultState }
		return reduce(action: event, state: state)
	}
	
	public func asReducer() -> Reducer<State> {
		reduceAny
	}
	
}

public protocol EventSource {
	var events: Observable<Action> { get }
}

extension ReducerModule where Self: AnyObject {
	
	public var weakReducer: Reducer<State> {
		let def = defaultState
		return {[weak self] in
			guard let event = $0 as? Event else { return def }
			return self?.reduce(action: event, state: $1 ?? def) ?? def
		}
	}
	
}

extension ReducerConvertible {
	
	public func asGlobal<State>(with lens: Lens<State, ReducerStateType>, default value: State) -> Reducer<State> {
		return { action, state in
			let state = state ?? value
			return lens.set(state, self.asReducer()(action, lens.get(state)))
		}
	}
	
}
