//
//  StoreSubscriber.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

public protocol AnyStoreSubscriber: AnyObject {
	// swiftlint:disable:next identifier_name
	func _newState(state: Any)
}

struct StoreSubscriberHashable: Hashable {
	var subscriber: AnyStoreSubscriber
	
	func hash(into hasher: inout Hasher) {
		ObjectIdentifier(subscriber).hash(into: &hasher)
	}
	
	static func ==(_ lhs: StoreSubscriberHashable, _ rhs: StoreSubscriberHashable) -> Bool {
		lhs.subscriber === rhs.subscriber
	}
	
}

public protocol StoreSubscriber: AnyStoreSubscriber {
	associatedtype StoreSubscriberStateType
	
	func newState(state: StoreSubscriberStateType)
}

extension StoreSubscriber {
	// swiftlint:disable:next identifier_name
	public func _newState(state: Any) {
		if let typedState = state as? StoreSubscriberStateType {
			newState(state: typedState)
		}
	}
}
