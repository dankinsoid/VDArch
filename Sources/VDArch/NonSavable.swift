//
//  NonSavable.swift
//  
//
//  Created by Данил Войдилов on 13.01.2021.
//

import Foundation
import VDKit

@propertyWrapper
public struct NonCacheable<Value: Codable>: Codable {
	
	public var wrappedValue: Value
	public var saveValue: Value
	
	public init(wrappedValue: Value, _ save: Value) {
		saveValue = save
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

extension NonCacheable where Value: OptionalProtocol {
	public init(wrappedValue: Value) {
		saveValue = .init(nil)
		self.wrappedValue = wrappedValue
	}
}

extension NonCacheable where Value: ExpressibleByArrayLiteral {
	public init(wrappedValue: Value) {
		saveValue = []
		self.wrappedValue = wrappedValue
	}
}

extension NonCacheable where Value: ExpressibleByDictionaryLiteral {
	public init(wrappedValue: Value) {
		saveValue = [:]
		self.wrappedValue = wrappedValue
	}
}

extension NonCacheable where Value: ExpressibleByStringLiteral {
	public init(wrappedValue: Value) {
		saveValue = ""
		self.wrappedValue = wrappedValue
	}
}

extension NonCacheable: Equatable where Value: Equatable {}
extension NonCacheable: Hashable where Value: Hashable {}
extension NonCacheable: Comparable where Value: Comparable {
	public static func <(lhs: NonCacheable<Value>, rhs: NonCacheable<Value>) -> Bool {
		lhs.wrappedValue < rhs.wrappedValue
	}
}
