//
//  Updates.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine
import CombineOperators

@available(iOS 13.0, *)
@propertyWrapper
@dynamicMemberLookup
public final class Updates<Input>: Subscriber {
	public typealias Failure = Never
	
	public var wrappedValue: AnyPublisher<Input, Never> { subject.eraseToAnyPublisher() }
	private let subject: PassthroughSubject<Input, Never>
	public var projectedValue: CombinePropertyMapper<PassthroughSubject<Input, Never>, Input> { subject.mp }
	
	public init() {
		self.subject = PassthroughSubject()
	}
	
	public init(subject: PassthroughSubject<Input, Never>) {
		self.subject = subject
	}
	
	public func receive(subscription: Subscription) {
		subject.send(subscription: subscription)
	}
	
	public func receive(_ input: Input) -> Subscribers.Demand {
		subject.send(input)
		return .unlimited
	}
	
	public func receive(completion: Subscribers.Completion<Never>) {}
	
	public func `as`<Result>(_ map: @escaping (Result) -> Input) -> Subscribers.MapSubscriber<Updates<Input>, Result> {
		mapSubscriber(map)
	}
	
	public func `as`(_ element: Input) -> Subscribers.MapSubscriber<Updates<Input>, Void> {
		mapSubscriber { element }
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Input, T>) -> CombinePropertyMapper<AnyPublisher<T, Never>, T> {
		subject.map(keyPath).any().mp
	}
}
