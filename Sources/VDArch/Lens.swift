//
//  TruRe.swift
//  VDArch
//
//  Created by Daniil on 25.07.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//
import Foundation

public struct Lens<State, SubState> {
	public let get: (State) -> SubState
	public let set: (State, SubState) -> State
	
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
	
}

extension Lens where State == SubState {
	
	public init() {
		self = Lens(at: \.self)
	}
	
}
