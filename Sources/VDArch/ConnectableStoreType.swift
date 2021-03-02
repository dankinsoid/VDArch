//
//  ConnectableStoreType.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation

public protocol ConnectableStoreType: StoreType {
	@discardableResult
	func connect(reducer: @escaping Reducer<State>) -> StoreUnsubscriber
}

extension ConnectableStoreType {
	
	@discardableResult
	public func connect<SubState>(reducer: @escaping Reducer<SubState>, lens: Lens<State, SubState>) -> StoreUnsubscriber {
		connect(reducer: ReducerWrapped(reducer), lens: lens)
	}
	
	@discardableResult
	public func connect<SubState>(reducer: @escaping Reducer<SubState>, at keyPath: WritableKeyPath<State, SubState>) -> StoreUnsubscriber {
		connect(reducer: reducer, lens: Lens(at: keyPath))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer, lens: Lens<State, Reducer.ReducerStateType>) -> StoreUnsubscriber {
		connect(reducer: reducer.asGlobal(with: lens))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer, at keyPath: WritableKeyPath<State, Reducer.ReducerStateType>) -> StoreUnsubscriber {
		connect(reducer: reducer, lens: Lens(at: keyPath))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer, at keyPath: WritableKeyPath<State, Reducer.ReducerStateType?>, or value: Reducer.ReducerStateType) -> StoreUnsubscriber {
		connect(reducer: reducer, lens: Lens(at: keyPath, or: value))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer) -> StoreUnsubscriber where Reducer.ReducerStateType == State {
		connect(reducer: reducer.asReducer())
	}
	
	@discardableResult
	public func connect<Reducer: ReducerConvertible, Key: Hashable>(reducer: Reducer, at keyPath: WritableKeyPath<State, [Key: Reducer.ReducerStateType]?>, key: Key, or value: Reducer.ReducerStateType) -> StoreUnsubscriber {
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

private final class ReducerWrapped<ReducerStateType>: ReducerConvertible {
	var reducer: Reducer<ReducerStateType>
	
	init(_ reducer: @escaping Reducer<ReducerStateType>) {
		self.reducer = reducer
	}
	
	func asReducer() -> Reducer<ReducerStateType> {
		return {
			self.reducer($0, $1)
		}
	}
}

