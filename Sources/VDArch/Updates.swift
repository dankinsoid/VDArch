//
//  Updates.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import RxSwift

@propertyWrapper
public final class Updates<Element>: ObserverType {
	public var wrappedValue: Observable<Element> { subject }
	private let subject = PublishSubject<Element>()
	public var projectedValue: Observable<Element> { subject }
	
	public init(wrappedValue initialValue: Observable<Element>) {}
	public init() {}
	
	public func on(_ event: Event<Element>) {
		subject.on(event)
	}
	
}
