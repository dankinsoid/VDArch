//
//  File.swift
//  
//
//  Created by Данил Войдилов on 24.02.2021.
//

import Foundation
import RxOperators
import RxSwift

@propertyWrapper
@dynamicMemberLookup
public final class Updater<Element>: ObservableType {
	private let subject = PublishSubject<Element>()
	public var projectedValue: AnyObserver<Element> { subject.asObserver() }
	public var wrappedValue: AnyObserver<Element> { subject.asObserver() }
	
	public init() {}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Element == Observer.Element {
		subject.subscribe(observer)
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> RxPropertyMapper<Observable<T>, T> {
		subject.map(keyPath).mp
	}
	
}
