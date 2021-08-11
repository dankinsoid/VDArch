//
//  File.swift
//  
//
//  Created by Данил Войдилов on 09.05.2021.
//

import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, *)
@propertyWrapper
public struct ViewModelEnvironment<Events, State>: DynamicProperty {
	@EnvironmentObject var store: ViewModelObject<Events, State>
	
	public var wrappedValue: State { store.state() }
	
	public var projectedValue: AnyPublisher<State, Never> {
		store.objectWillChange.map { store.state() }.eraseToAnyPublisher()
	}
	
	public init() {}
	
	public func send(_ event: Events) {
		store.send(event)
	}
}

extension ViewModelEnvironment {
	
	public func binding<T>(get: KeyPath<State, T>, set: @escaping (T) -> Events) -> Binding<T> {
		Binding(get: { wrappedValue[keyPath: get] }, set: { send(set($0)) })
	}
	
	public func binding<T>(_ value: T, set: @escaping (T) -> Events) -> Binding<T> {
		Binding(get: { value }, set: { send(set($0)) })
	}
}

@available(iOS 13.0, *)
public protocol MVVMView: View {
	associatedtype Properties
	associatedtype Events
	typealias MVVMState = ViewModelEnvironment<Events, Properties>
}

@available(iOS 13.0, *)
extension MVVMView {
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events, VM.State == State {
		let object = ViewModelObject(
			store.cb.dropFirst().map(viewModel.map),
			value: { viewModel.map(state: store.state) },
			send: { viewModel.map(event: $0, state: store.state).subscribe(store.cb.dispatcher) }
		)
		subscribe(store: store, viewModel: viewModel, until: object.deallocated, map: { $0 })
		return environmentObject(object)
	}
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>, get: @escaping (State) -> VM.State) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events {
		let object = ViewModelObject(
			store.cb.dropFirst().map { viewModel.map(state: get($0)) }.asDriver(),
			value: { viewModel.map(state: get(store.state)) },
			send: { viewModel.map(event: $0, state: get(store.state)).subscribe(store.cb.dispatcher) }
		)
		subscribe(store: store, viewModel: viewModel, until: object.deallocated, map: get)
		return environmentObject(object)
	}
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>, at keyPath: KeyPath<State, VM.State>) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events {
		self.viewModel(viewModel, store: store, get: { $0[keyPath: keyPath] })
	}
	
	public func viewModel<P, E>(_ viewModel: MVVMState, state: @escaping (Properties) -> P, events: @escaping (E) -> Events) -> some View {
		environmentObject(viewModel.store.map(properties: state, events: events))
	}
	
	public func viewModel<P, E>(_ viewModel: MVVMState, _ keyPath: KeyPath<Properties, P>, events: @escaping (E) -> Events) -> some View {
		self.viewModel(viewModel, state: { $0[keyPath: keyPath] }, events: events)
	}
	
	public func viewModel<P: Equatable, E>(_ viewModel: MVVMState, state: @escaping (Properties) -> P, events: @escaping (E) -> Events) -> some View {
		environmentObject(viewModel.store.map(properties: state, events: events))
	}
	
	public func viewModel<P: Equatable, E>(_ viewModel: MVVMState, _ keyPath: KeyPath<Properties, P>, events: @escaping (E) -> Events) -> some View {
		self.viewModel(viewModel, state: { $0[keyPath: keyPath] }, events: events)
	}
	
	public func viewModel(_ properties: Properties) -> some View {
		environmentObject(ViewModelObject<Events, Properties>(Empty(), value: { properties }, send: {_ in}))
	}
	
	private func subscribe<VM: ViewModelProtocol, State: StateType, P: Publisher>(store: Store<State>, viewModel: VM, until: P, map: @escaping (State) -> VM.State) {
		store.cb.actions
			.prefix(untilOutputFrom: until)
			.flatMap(viewModel.onAction)
			.subscribe(store.cb.dispatcher)
		
		store.cb.onChange
			.prefix(untilOutputFrom: until)
			.map { ($0.0.map(map), map($0.1)) }
			.filter { $0.0 != $0.1 && $0.0 != nil }
			.flatMap { viewModel.onChange(oldState: $0.0!, newState: $0.1) }
			.subscribe(store.cb.dispatcher)
	}
}

@available(iOS 13.0, *)
extension MVVMView where Properties: Equatable {
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events, VM.State == State {
		let object = ViewModelObject(
			store.cb.dropFirst().map(viewModel.map).removeDuplicates().asDriver(),
			value: { viewModel.map(state: store.state) },
			send: { viewModel.map(event: $0, state: store.state).subscribe(store.cb.dispatcher) }
		)
		subscribe(store: store, viewModel: viewModel, until: object.deallocated, map: { $0 })
		return environmentObject(object)
	}
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>, get: @escaping (State) -> VM.State) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events {
		let object = ViewModelObject(
			store.cb.dropFirst().map { viewModel.map(state: get($0)) }.removeDuplicates().asDriver(),
			value: { viewModel.map(state: get(store.state)) },
			send: { viewModel.map(event: $0, state: get(store.state)).subscribe(store.cb.dispatcher) }
		)
		subscribe(store: store, viewModel: viewModel, until: object.deallocated, map: get)
		return environmentObject(object)
	}
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>, at keyPath: KeyPath<State, VM.State>) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events {
		self.viewModel(viewModel, store: store, get: { $0[keyPath: keyPath] })
	}
}

@available(iOS 13.0, *)
final class ViewModelObject<Events, State>: ObservableObject {
	var send: (Events) -> Void
	let state: () -> State
	let deallocated = PassthroughSubject<Void, Never>()
	private let publisher: AnyPublisher<State, Never>
	
	init<P: Publisher>(_ publisher: P, value: @escaping () -> State, send: @escaping (Events) -> Void) where P.Output == State, P.Failure == Never {
		self.state = value
		self.send = send
		self.publisher = publisher.eraseToAnyPublisher()
		subscribe(publisher)
	}
	
	private func subscribe<P: Publisher>(_ publisher: P) where P.Output == State, P.Failure == Never {
		publisher
			.prefix(untilOutputFrom: deallocated)
			.subscribe {[weak self] state in
				self?.objectWillChange.send()
			}
	}
	
	func map<E, S>(properties: @escaping (State) -> S, events: @escaping (E) -> Events) -> ViewModelObject<E, S> {
		ViewModelObject<E, S>(publisher.map(properties), value: {[state] in properties(state()) }, send: { self.send(events($0)) })
	}
	
	func map<E, S: Equatable>(properties: @escaping (State) -> S, events: @escaping (E) -> Events) -> ViewModelObject<E, S> {
		ViewModelObject<E, S>(publisher.map(properties).removeDuplicates(), value: {[state] in properties(state()) }, send: { self.send(events($0)) })
	}
	
	deinit {
		deallocated.send()
	}
}
