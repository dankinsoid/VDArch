//
//  StateDriver.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import VDKit
import Combine
import CombineCocoa
import CombineOperators

@available(iOS 13.0, *)
@dynamicMemberLookup
public struct StateDriver<Output>: Publisher {
	public typealias Failure = Never
	private let driver: Driver<Output>
	
	public init<P: Publisher>(_ publisher: P) where P.Output == Output {
		self.driver = publisher.asDriver()
	}
	
	public init(_ driver: Driver<Output>) {
		self.driver = driver
	}
	
	public init(just: Output) {
		self = StateDriver(Just(just))
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StateDriver<T> {
		return map { $0[keyPath: keyPath] }
	}
	
	public func map<T>(_ selector: @escaping (Output) -> T) -> StateDriver<T> {
		return StateDriver<T>(driver.map(selector))
	}
	
	public func compactMap<T>(_ selector: @escaping (Output) -> T?) -> StateDriver<T> {
		StateDriver<T>(driver.compactMap(selector))
	}
	
	public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
		driver.receive(subscriber: subscriber)
	}
	
}

@available(iOS 13.0, *)
extension StateDriver where Output: Equatable {
	
	public func skipEqual() -> StateDriver {
		StateDriver(driver.removeDuplicates())
	}
}

@available(iOS 13.0, *)
extension StateDriver where Output: OptionalProtocol {
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output.Wrapped, T>) -> StateDriver<T?> {
		return map { $0.asOptional()?[keyPath: keyPath] }
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output.Wrapped, T?>) -> StateDriver<T?> {
		return map { $0.asOptional()?[keyPath: keyPath] }
	}
	
}

@available(iOS 13.0, *)
extension StateDriver where Output == Void {
	
	public func map<T>(_ selector: @escaping () -> T) -> StateDriver<T> {
		return StateDriver<T>(driver.map(selector))
	}
	
}

@available(iOS 13.0, *)
extension StateDriver {
	
	public func skipEqual<E: Equatable>(by keyPath: KeyPath<Output, E>) -> StateDriver {
		skipEqual { $0[keyPath: keyPath] }
	}
	
	public func skipEqual<E: Equatable>(_ comparor: @escaping (Output) -> E) -> StateDriver {
		StateDriver(driver.removeDuplicates(by: { comparor($0) != comparor($1) }))
	}
	
}

@available(iOS 13.0, *)
extension Publisher {
	public func asState() -> StateDriver<Output> {
		StateDriver(self)
	}
}

@available(iOS 13.0, *)
public func =><V: ViewProtocol, O: Publisher>(_ lhs: O, _ rhs: Reactive<V>) where O.Output == V.Properties {
	lhs => rhs.base.properties
}
