import Foundation

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

extension NonCacheable {
    
	public init<T>(wrappedValue: Value) where T? == Value {
		saveValue = nil
        self.wrappedValue = wrappedValue
	}
	
	public init<T>() where T? == Value {
		saveValue = nil
        wrappedValue = nil
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
