//
//  File.swift
//  
//
//  Created by Данил Войдилов on 14.01.2021.
//

import Foundation

public struct UnionState<A, B> {
	public var a: A
	public var b: B
	
	public init(_ a: A, _ b: B) {
		self.a = a
		self.b = b
	}
}

extension UnionState: Equatable where A: Equatable, B: Equatable {}
extension UnionState: Hashable where A: Hashable, B: Hashable {}
extension UnionState: Decodable where A: Decodable, B: Decodable {}
extension UnionState: Encodable where A: Encodable, B: Encodable {}
