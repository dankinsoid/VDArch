//
//  Updates.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import RxSwift
import RxOperators

@propertyWrapper
@dynamicMemberLookup
public struct Updates<Element>: ObserverType {
	public var wrappedValue: Observable<Element> { subject }
	private let subject: PublishSubject<Element>
	public var projectedValue: RxPropertyMapper<Observable<Element>, Element> { subject.asObservable().mp }
	
	public init() {
		self.subject = PublishSubject()
	}
	
	public init(subject: PublishSubject<Element>) {
		self.subject = subject
	}
	
	public func on(_ event: Event<Element>) {
		subject.on(event)
	}
	
	public func `as`<Result>(_ map: @escaping (Result) throws -> Element) -> AnyObserver<Result> {
		asObserver().mapObserver(map)
	}
	
	public func `as`(_ element: Element) -> AnyObserver<Void> {
		asObserver().mapObserver { element }
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> RxPropertyMapper<Observable<T>, T> {
		subject.map(keyPath).mp
	}
	
}
