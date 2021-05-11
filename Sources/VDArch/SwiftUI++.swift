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
	
	public var wrappedValue: State { store.state }
	
	public var projectedValue: AnyPublisher<State, Never> {
		store.objectWillChange.map { store.state }.eraseToAnyPublisher()
	}
	
	public init() {}
	
	public func send(_ event: Events) {
		store.send(event)
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
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events, VM.ModelState == State {
		environmentObject(
			ViewModelObject(
				store.cb.dropFirst().map(viewModel.map),
				value: viewModel.map(state: store.state),
				send: { viewModel.map(event: $0, state: store.state).subscribe(store.cb.dispatcher) }
			)
		)
	}
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>, get: @escaping (State) -> VM.ModelState) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events {
		environmentObject(
			ViewModelObject(
				store.cb.dropFirst().map { viewModel.map(state: get($0)) }.asDriver(),
				value: viewModel.map(state: get(store.state)),
				send: { viewModel.map(event: $0, state: get(store.state)).subscribe(store.cb.dispatcher) }
			)
		)
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
		environmentObject(ViewModelObject<Events, Properties>(Empty(), value: properties, send: {_ in}))
	}
}

@available(iOS 13.0, *)
extension MVVMView where Properties: Equatable {
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events, VM.ModelState == State {
		environmentObject(
			ViewModelObject(
				store.cb.dropFirst().map(viewModel.map).removeDuplicates().asDriver(),
				value: viewModel.map(state: store.state),
				send: { viewModel.map(event: $0, state: store.state).subscribe(store.cb.dispatcher) }
			)
		)
	}
	
	public func viewModel<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, store: Store<State>, get: @escaping (State) -> VM.ModelState) -> some View where VM.ViewState == Properties, VM.ViewEvents == Events {
		environmentObject(
			ViewModelObject(
				store.cb.dropFirst().map { viewModel.map(state: get($0)) }.removeDuplicates().asDriver(),
				value: viewModel.map(state: get(store.state)),
				send: { viewModel.map(event: $0, state: get(store.state)).subscribe(store.cb.dispatcher) }
			)
		)
	}
}

@available(iOS 13.0, *)
final class ViewModelObject<Events, State>: ObservableObject {
	@Published var state: State
	var send: (Events) -> Void
	let deallocated = PassthroughSubject<Void, Never>()
	private let publisher: AnyPublisher<State, Never>
	
	init<P: Publisher>(_ publisher: P, value: State, send: @escaping (Events) -> Void) where P.Output == State, P.Failure == Never {
		self.state = value
		self.send = send
		self.publisher = publisher.eraseToAnyPublisher()
		subscribe(publisher)
	}
	
	private func subscribe<P: Publisher>(_ publisher: P) where P.Output == State, P.Failure == Never {
		publisher
			.prefix(untilOutputFrom: deallocated)
			.subscribe {[weak self] state in
				self?.state = state
			}
	}
	
	func map<E, S>(properties: @escaping (State) -> S, events: @escaping (E) -> Events) -> ViewModelObject<E, S> {
		ViewModelObject<E, S>(publisher.map(properties), value: properties(state), send: { self.send(events($0)) })
	}
	
	func map<E, S: Equatable>(properties: @escaping (State) -> S, events: @escaping (E) -> Events) -> ViewModelObject<E, S> {
		ViewModelObject<E, S>(publisher.map(properties).removeDuplicates(), value: properties(state), send: { self.send(events($0)) })
	}
	
	deinit {
		deallocated.send()
	}
}
