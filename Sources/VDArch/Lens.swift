//
//  TruRe.swift
//  VDArch
//
//  Created by Daniil on 25.07.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//
import Foundation

@dynamicMemberLookup
public struct Lens<State, SubState> {
	public var get: (State) -> SubState
	public var set: (State, SubState) -> State
	
	public init(get: @escaping (State) -> SubState, set: @escaping (State, SubState) -> State) {
		self.get = get
		self.set = set
	}
	
	public init(at keyPath: WritableKeyPath<State, SubState>) {
		self.get = { $0[keyPath: keyPath] }
		self.set = {
			var result = $0
			result[keyPath: keyPath] = $1
			return result
		}
	}
	
	public init(at keyPath: WritableKeyPath<State, SubState?>, or defaultValue: SubState) {
		self.get = { $0[keyPath: keyPath] ?? defaultValue }
		self.set = {
			var result = $0
			result[keyPath: keyPath] = $1
			return result
		}
	}
	
	public func sublens<S>(_ lens: Lens<SubState, S>) -> Lens<State, S> {
		Lens<State, S>(
			get: { state in lens.get(self.get(state)) },
			set: { state, s in self.set(state, lens.set(self.get(state), s)) }
		)
	}
	
	public func sublens<S>(get: @escaping (SubState) -> S, set: @escaping (SubState, S) -> SubState) -> Lens<State, S> {
		sublens(Lens<SubState, S>(get: get, set: set))
	}
	
	public func sublens<S>(at keyPath: WritableKeyPath<SubState, S>) -> Lens<State, S> {
		sublens(
			get: { $0[keyPath: keyPath] },
			set: {
				var result = $0
				result[keyPath: keyPath] = $1
			 	return result
			}
		)
	}
	
	public subscript<S>(dynamicMember keyPath: WritableKeyPath<SubState, S>) -> Lens<State, S> {
		sublens(at: keyPath)
	}
	
}

public func +<State, Sub, SubSub>(_ lhs: Lens<State, Sub>, _ rhs: Lens<Sub, SubSub>) -> Lens<State, SubSub> {
	lhs.sublens(rhs)
}

extension Lens where State == SubState {
	
	public init() {
		self = Lens(at: \.self)
	}
	
}
