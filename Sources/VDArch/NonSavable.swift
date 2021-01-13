//
//  NonSavable.swift
//  
//
//  Created by Данил Войдилов on 13.01.2021.
//

import Foundation

@propertyWrapper
public struct NonCacheable<Value: Codable>: Codable {
	
	public var wrappedValue: Value
	public var saveValue: Value
	
	public init(wrappedValue: Value, _ save: Value) {
		saveValue = save
		self.wrappedValue = wrappedValue
	}
	
	public init(wrappedValue: Value) {
		saveValue = wrappedValue
		self.wrappedValue = wrappedValue
	}
	
	public init(from decoder: Decoder) throws {
		wrappedValue = try Value(from: decoder)
		saveValue = wrappedValue
	}
	
	public func encode(to encoder: Encoder) throws {
		try saveValue.encode(to: encoder)
	}
	
}

extension NonCacheable: Equatable where Value: Equatable {}
extension NonCacheable: Hashable where Value: Hashable {}
extension NonCacheable: Comparable where Value: Comparable {
	public static func <(lhs: NonCacheable<Value>, rhs: NonCacheable<Value>) -> Bool {
		lhs.wrappedValue < rhs.wrappedValue
	}
}
