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
@available(iOS, deprecated, message: "use StateSignal")
public typealias StateDriver<T> = StateSignal<T>

@available(iOS 13.0, *)
@dynamicMemberLookup
public struct StateSignal<Output>: Publisher {
	public typealias Failure = Never
	fileprivate let signal: AnyPublisher<Output, Never>
	private let needMain: Bool
	
	public init<P: Publisher>(_ publisher: P) where P.Output == Output {
		self.signal = publisher.skipFailure().any()
		needMain = true
	}
	
	public init(signal: Signal<Output>) {
		self.signal = signal.any()
		needMain = false
	}
	
	public init(driver: Driver<Output>) {
		self.signal = driver.any()
		needMain = false
	}
	
	public init(signal: StateSignal<Output>) {
		self.signal = signal.signal
		needMain = signal.needMain
	}
	
	fileprivate init(any signal: AnyPublisher<Output, Never>, needMain: Bool) {
		self.signal = signal
		self.needMain = needMain
	}
	
	public init(just: Output) {
		self = StateSignal(Just(just))
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StateSignal<T> {
		return map { $0[keyPath: keyPath] }
	}
	
	public func map<T>(_ selector: @escaping (Output) -> T) -> StateSignal<T> {
		StateSignal<T>(any: signal.map(selector).any(), needMain: needMain)
	}
	
	public func compactMap<T>(_ selector: @escaping (Output) -> T?) -> StateSignal<T> {
		StateSignal<T>(any: signal.compactMap(selector).any(), needMain: needMain)
	}
	
	public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
		if needMain {
			signal.receive(subscriber: MainQueueSubscriber(subscriber: subscriber))
		} else {
			signal.receive(subscriber: subscriber)
		}
	}
}

@available(iOS 13.0, *)
extension StateSignal where Output: Equatable {
	
	public func skipEqual() -> StateSignal {
		StateSignal(any: signal.removeDuplicates().any(), needMain: needMain)
	}
}

@available(iOS 13.0, *)
extension StateSignal where Output: OptionalProtocol {
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output.Wrapped, T>) -> StateSignal<T?> {
		return map { $0.asOptional()?[keyPath: keyPath] }
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output.Wrapped, T?>) -> StateSignal<T?> {
		return map { $0.asOptional()?[keyPath: keyPath] }
	}
	
}

@available(iOS 13.0, *)
extension StateSignal where Output == Void {
	
	public func map<T>(_ selector: @escaping () -> T) -> StateSignal<T> {
		return StateSignal<T>(signal.map(selector))
	}
	
}

@available(iOS 13.0, *)
extension StateSignal {
	
	public func skipEqual<E: Equatable>(by keyPath: KeyPath<Output, E>) -> StateSignal {
		skipEqual { $0[keyPath: keyPath] }
	}
	
	public func skipEqual<E: Equatable>(_ comparor: @escaping (Output) -> E) -> StateSignal {
		StateSignal(signal.removeDuplicates(by: { comparor($0) != comparor($1) }))
	}
	
}

@available(iOS 13.0, *)
extension Publisher {
	public func asState() -> StateSignal<Output> {
		StateSignal(self)
	}
}

@available(iOS 13.0, *)
public func =><V: ViewProtocol, O: Publisher>(_ lhs: O, _ rhs: Reactive<V>) where O.Output == V.Properties {
	rhs.base.bind(lhs)
}
