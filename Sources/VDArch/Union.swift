//
//  File.swift
//  
//
//  Created by Данил Войдилов on 14.01.2021.
//

import Foundation

public struct Union<A, B> {
	public var a: A
	public var b: B
	
	public init(_ a: A, _ b: B) {
		self.a = a
		self.b = b
	}
}

extension Union: StateType where A: StateType, B: StateType {}
extension Union: Equatable where A: Equatable, B: Equatable {}
extension Union: Hashable where A: Hashable, B: Hashable {}
