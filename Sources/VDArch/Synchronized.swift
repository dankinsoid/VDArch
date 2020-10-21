//
//  Synchronized.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation

@propertyWrapper
public struct Synchronized<Value> {
	
	public var wrappedValue: Value {
		get {
			lock.lock()
			let result = value
			lock.unlock()
			return result
		}
		set {
			lock.lock()
			value = newValue
			lock.unlock()
		}
	}
	private var value: Value
	private let lock = NSRecursiveLock()
	
	public init(wrappedValue: Value) {
		value = wrappedValue
	}
	
}
