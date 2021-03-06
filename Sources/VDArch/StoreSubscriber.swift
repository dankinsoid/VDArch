//
//  StoreSubscriber.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//
import VDKit

public protocol AnyStoreSubscriber {
	// swiftlint:disable:next identifier_name
	var objectIdentifier: ObjectIdentifier { get }
	func _newState(state: Any, oldState: Any?)
}

extension AnyStoreSubscriber where Self: AnyObject {
	public var objectIdentifier: ObjectIdentifier { ObjectIdentifier(self) }
}

struct StoreSubscriberHashable: Hashable {
	let getObjectIdentifier: () -> ObjectIdentifier
	let newState: (Any, Any?) -> Void
	
	init(_ subscriber: AnyStoreSubscriber) {
		self.getObjectIdentifier = { subscriber.objectIdentifier }
		self.newState = subscriber._newState
	}
	
	func hash(into hasher: inout Hasher) {
		getObjectIdentifier().hash(into: &hasher)
	}
	
	static func ==(_ lhs: StoreSubscriberHashable, _ rhs: StoreSubscriberHashable) -> Bool {
		lhs.getObjectIdentifier() == rhs.getObjectIdentifier()
	}
	
}

public protocol StoreSubscriber: AnyStoreSubscriber {
	associatedtype StoreSubscriberStateType
	func newState(state: StoreSubscriberStateType, oldState: StoreSubscriberStateType?)
}

public struct MapStoreSubscriber<StoreSubscriberStateType>: StoreSubscriber {
	let subscribe: (StoreSubscriberStateType, StoreSubscriberStateType?) -> Void
	let getObjectIdentifier: () -> ObjectIdentifier
	public var objectIdentifier: ObjectIdentifier { getObjectIdentifier() }
	
	public func newState(state: StoreSubscriberStateType, oldState: StoreSubscriberStateType?) {
		subscribe(state, oldState)
	}
	
}

extension StoreSubscriber {
	
	// swiftlint:disable:next identifier_name
	public func _newState(state: Any, oldState: Any?) {
		if let typedState = state as? StoreSubscriberStateType {
			newState(state: typedState, oldState: oldState as? StoreSubscriberStateType)
		}
	}
	
	public func map<T>(_ block: @escaping (T) -> StoreSubscriberStateType) -> MapStoreSubscriber<T> {
		MapStoreSubscriber(
			subscribe: { new, old in
				self.newState(state: block(new), oldState: old.map(block))
			},
			getObjectIdentifier: { self.objectIdentifier }
		)
	}
	
}

extension StoreSubscriber where StoreSubscriberStateType: OptionalProtocol {
	
	public func skipNil() -> MapStoreSubscriber<StoreSubscriberStateType.Wrapped> {
		MapStoreSubscriber(
			subscribe: { new, old in
				newState(state: .init(.some(new)), oldState: old.map { .init(.some($0)) })
			},
			getObjectIdentifier: { self.objectIdentifier }
		)
	}
	
}
