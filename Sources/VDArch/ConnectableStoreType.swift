//
//  ConnectableStoreType.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine

public protocol ConnectableStoreType: StoreType {
	@discardableResult
	func connect(reducer: @escaping Reducer<State>) -> StoreUnsubscriber
}

extension ConnectableStoreType {
	
	@discardableResult
    public func connect<SubState: Equatable>(reducer: @escaping Reducer<SubState>, lens: Lens<State, SubState>) -> StoreUnsubscriber {
		connect(reducer: ReducerWrapped(reducer), lens: lens)
	}
	
	@discardableResult
	public func connect<SubState: Equatable>(reducer: @escaping Reducer<SubState>, at keyPath: WritableKeyPath<State, SubState>) -> StoreUnsubscriber {
		connect(reducer: reducer, lens: Lens(at: keyPath))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerBaseModule>(reducer: Reducer, lens: Lens<State, Reducer.State>) -> StoreUnsubscriber {
		connect(reducer: reducer.asGlobal(with: lens))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerBaseModule>(reducer: Reducer, at keyPath: WritableKeyPath<State, Reducer.State>) -> StoreUnsubscriber {
		connect(reducer: reducer, lens: Lens(at: keyPath))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerBaseModule>(reducer: Reducer, at keyPath: WritableKeyPath<State, Reducer.State?>, or value: Reducer.State) -> StoreUnsubscriber {
		connect(reducer: reducer, lens: Lens(at: keyPath, or: value))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerBaseModule>(reducer: Reducer) -> StoreUnsubscriber where Reducer.State == State {
		connect(reducer: reducer.reduceAny)
	}
	
	@discardableResult
	public func connect<Reducer: ReducerBaseModule, Key: Hashable>(reducer: Reducer, at keyPath: WritableKeyPath<State, [Key: Reducer.State]?>, key: Key, or value: Reducer.State) -> StoreUnsubscriber {
		connect(
			reducer: reducer,
			lens: Lens(
				get: {
					$0[keyPath: keyPath]?[key] ?? value
				},
				set: {
					var result = $0
					if result[keyPath: keyPath] == nil {
						result[keyPath: keyPath] = [:]
					}
					result[keyPath: keyPath]?[key] = $1
					return result
				}
			)
		)
	}
	
}

public struct StoreUnsubscriber {
	
	let action: () -> Void
	
	public func unsubscribe() {
		action()
	}
	
}

private final class ReducerWrapped<State: Equatable>: ReducerBaseModule {
	var reducer: Reducer<State>
	
	init(_ reducer: @escaping Reducer<State>) {
		self.reducer = reducer
	}
	
    func reduceAny(action: Action, state: inout State) -> AnyPublisher<Action, Never> {
        reducer(action, &state)
    }
}

