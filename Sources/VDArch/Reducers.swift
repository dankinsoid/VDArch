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
	func reduceAny(action: Action, state: inout State) -> AnyPublisher<Action, Never>
}

extension ReducerBaseModule {
	
	public func reduce(actions: Action..., state: inout State) -> AnyPublisher<Action, Never> {
		var state = state
        var results: [AnyPublisher<Action, Never>] = []
		for action in actions {
            results.append(reduceAny(action: action, state: &state))
		}
        return Publishers.MergeMany(results).any()
	}
}

public protocol ReducerModule: ReducerBaseModule {
	associatedtype Event: Action
	func reduce(action: Event, state: inout State) -> AnyPublisher<Action, Never>
}

extension ReducerModule where State == Never {
    public func reduce(action: Event, state: inout State) -> AnyPublisher<Action, Never> { .empty() }
}

extension ReducerModule {
	
	public func reduceAny(action: Action, state: inout State) -> AnyPublisher<Action, Never> {
        guard let event = action as? Event else { return .empty() }
		return reduce(action: event, state: &state)
      
	}
}

extension ReducerBaseModule {
	
    public func asGlobal<S: Equatable>(with lens: Lens<S, State>) -> Reducer<S> {
		return { action, state in
            var newState = lens.get(state)
         
            let result = self.reduceAny(action: action, state: &newState)
            state = lens.set(state, newState)
            return result
		}
	}
}
