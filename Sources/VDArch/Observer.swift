//
//  File.swift
//  
//
//  Created by Данил Войдилов on 24.02.2021.
//

import Foundation
import CombineOperators
import Combine

@available(iOS 13.0, *)
@propertyWrapper
@dynamicMemberLookup
public struct Observer<Output>: Publisher {
	public typealias Failure = Never
	private let subject: PassthroughSubject<Output, Never>
	public var projectedValue: AnySubscriber<Output, Never> { subject.asSubscriber() }
	public var wrappedValue: AnySubscriber<Output, Never> { subject.asSubscriber() }
	
	public init() {
		self.subject = PassthroughSubject()
	}
	
	public init(subject: PassthroughSubject<Output, Never>) {
		self.subject = subject
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
		subject.receive(subscriber: subscriber)
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> CombinePropertyMapper<AnyPublisher<T, Never>, T> {
		subject.map(keyPath).any().mp
	}
	
}

@available(iOS 13.0, *)
extension Subject {
	func asSubscriber() -> AnySubscriber<Output, Failure> {
		AnySubscriber {
			self.send(subscription: $0)
		} receiveValue: {
			self.send($0)
			return .unlimited
		} receiveCompletion: {
			self.send(completion: $0)
		}
	}
}
