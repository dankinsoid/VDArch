//
//  ConnectableStoreType.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation

public protocol ConnectableStoreType: StoreType {
	func connect(reducer: @escaping Reducer<State>) -> ReducerDisconnecter
}

extension ConnectableStoreType {
	
	public func connect<SubState>(reducer: @escaping Reducer<SubState>, lens: Lens<State, SubState>) -> ReducerDisconnecter {
		connect(reducer: ReducerWrapped(reducer), lens: lens)
	}
	
	public func connect<SubState>(reducer: @escaping Reducer<SubState>, at keyPath: WritableKeyPath<State, SubState>) -> ReducerDisconnecter {
		connect(reducer: reducer, lens: Lens(at: keyPath))
	}
	
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer, lens: Lens<State, Reducer.ReducerStateType>) -> ReducerDisconnecter {
		connect(reducer: reducer.asGlobal(with: lens))
	}
	
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer, at keyPath: WritableKeyPath<State, Reducer.ReducerStateType>) -> ReducerDisconnecter {
		connect(reducer: reducer, lens: Lens(at: keyPath))
	}
	
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer, at keyPath: WritableKeyPath<State, Reducer.ReducerStateType?>, or value: Reducer.ReducerStateType) -> ReducerDisconnecter {
		connect(reducer: reducer, lens: Lens(at: keyPath, or: value))
	}
	
	@discardableResult
	public func connect<Reducer: ReducerConvertible>(reducer: Reducer) -> ReducerDisconnecter where Reducer.ReducerStateType == State {
		connect(reducer: reducer.asReducer())
	}
	
	public func connect<Reducer: ReducerConvertible, Key: Hashable>(reducer: Reducer, at keyPath: WritableKeyPath<State, [Key: Reducer.ReducerStateType]?>, key: Key, or value: Reducer.ReducerStateType) -> ReducerDisconnecter {
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

public struct ReducerDisconnecter {
	
	let action: () -> Void
	
	public func disconnect() {
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

