//
//  StoreType.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

/**
Defines the interface of Stores in VDArch. `Store` is the default implementation of this
interface. Applications have a single store that stores the entire application state.
Stores receive actions and use reducers combined with these actions, to calculate state changes.
Upon every state update a store informs all of its subscribers.
*/

public protocol StoreType: DispatchingStoreType {
	
	associatedtype State: Equatable
	
	/// The current state stored in the store.
	var state: State { get }
	
	/**
	Subscribes the provided subscriber to this store.
	Subscribers will receive a call to `newState` whenever the
	state in this store changes.
	
	- parameter subscriber: Subscriber that will receive store updates
	- note: Subscriptions are not ordered, so an order of state updates cannot be guaranteed.
	*/
	@discardableResult
	func subscribe<S: StoreSubscriber>(_ subscriber: S) -> StoreUnsubscriber where S.StoreSubscriberStateType == State
	
	/**
	Unsubscribes the provided subscriber. The subscriber will no longer
	receive state updates from this store.
	
	- parameter subscriber: Subscriber that will be unsubscribed
	*/
	func unsubscribe(_ subscriber: AnyStoreSubscriber)
}
