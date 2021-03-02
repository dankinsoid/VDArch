//
//  MVVM.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine
import CombineOperators

@available(iOS 13.0, *)
public protocol ViewProtocol {
	associatedtype Properties
	associatedtype Events
	typealias EventsBuilder = MergeBuilder<Events>
	var properties: AnySubscriber<Properties, Never> { get }
	var events: AnyPublisher<Events, Never> { get }
	
	@available(*, deprecated, message: "use '@Updater var properties: AnySubscriber<Properties, Never>' instead")
	func bind(state: StateDriver<Properties>)
}

@available(iOS 13.0, *)
extension ViewProtocol {
	public func bind(state: StateDriver<Properties>) -> Cancellable {
		state.subscribe(properties)
		return AnyCancellable()
	}
}

@available(iOS 13.0, *)
public protocol ViewModelProtocol {
	associatedtype ModelState: Equatable
	associatedtype ViewState
	associatedtype ViewEvents
	
	func map(state: ModelState) -> ViewState
	func map(event: ViewEvents, state: ModelState) -> AnyPublisher<Action, Never>
}

@available(iOS 13.0, *)
extension ViewModelProtocol where ModelState == ViewState {
	public func map(state: ModelState) -> ViewState { state }
}

@available(iOS 13.0, *)
extension ViewModelProtocol where ViewEvents: Action {
	public func map(event: ViewEvents, state: ModelState) -> AnyPublisher<Action, Never> { Just(event).any() }
}

@available(iOS 13.0, *)
extension ViewProtocol {
	
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>, getter: @escaping (State) -> VM.ModelState) where VM.ViewState == Properties, VM.ViewEvents == Events {
		let source = store.cb.map(getter).skipEqual()
		let driver = source.map { viewModel.map(state: $0) }.asDriver()
		driver.subscribe(properties)
		bind(state: StateDriver(driver))
		events.flatMap {[weak store] event -> AnyPublisher<Action, Never> in
			guard let state = store?.state else { return Empty(completeImmediately: false).any() }
			return viewModel.map(event: event, state: getter(state)).skipFailure().any()
		}
		.subscribe(store.cb.dispatcher)
	}
	
	public func bind<VM: ViewModelProtocol, MS: StateType, VS: StateType>(_ viewModel: VM, modelStore: Store<MS>, viewStore: Store<VS>, getter: @escaping (MS, VS) -> VM.ModelState) where VM.ViewState == Properties, VM.ViewEvents == Events {
		let source: AnyPublisher<VM.ModelState, Never>
		if viewStore === modelStore, VM.self == MS.self {
			source = modelStore.cb.map { getter($0, $0 as! VS) }.skipEqual().any()
		} else {
			source = modelStore.cb.combineLatest(viewStore.cb).map(getter).skipEqual().any()
		}
		let driver = source.map { viewModel.map(state: $0) }.asDriver()
		driver.subscribe(properties)
		bind(state: StateDriver(driver))
		
		let cbEvents = events.skipFailure().flatMap {[weak viewStore, weak modelStore] event -> AnyPublisher<Action, Never> in
			guard let model = modelStore?.state, let view = viewStore?.state else { return Empty<Action, Never>(completeImmediately: false).any() }
			return viewModel.map(event: event, state: getter(model, view)).any()
		}.share()
		
		cbEvents.subscribe(viewStore.cb.dispatcher)
		if modelStore !== viewStore {
			cbEvents.bind(to: modelStore.cb.dispatcher)
		}
	}
	
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>, at keyPath: KeyPath<State, VM.ModelState>) where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] })
	}
	
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>, at keyPath: KeyPath<State, VM.ModelState?>, or value: VM.ModelState) where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] ?? value })
	}
	
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>) where VM.ViewState == Properties, VM.ViewEvents == Events, VM.ModelState == State {
		bind(viewModel, in: store, getter: { $0 })
	}
	
	public func bind<O: Publisher>(_ state: O) where O.Output == Properties {
		let asState = state.asState()
		asState.subscribe(properties)
		bind(state: asState)
	}
	
	public func bind<Source: Publisher, Observer: Subscriber>(source: Source, observer: Observer) where Source.Output == Properties, Observer.Input == Events {
		bind(source)
		events.subscribe(observer.ignoreFailure())
	}
	
}

@available(iOS 13.0, *)
extension ViewProtocol where Self: AnyObject {

	public func set(state: Properties) {
		_propertiesSubject.send(state)
	}
	
	private var _propertiesSubject: PassthroughSubject<Properties, Never> {
		get {
			if let subject = objc_getAssociatedObject(self, &propertiesSubjectKey) as? PassthroughSubject<Properties, Never> {
				return subject
			}
			let subject = PassthroughSubject<Properties, Never>()
			objc_setAssociatedObject(self, &propertiesSubjectKey, subject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			bind(subject)
			return subject
		}
		set {}
	}
	
}

private var propertiesSubjectKey = "_propertiesSubject"
private var eventsSubjectKey = "_eventsSubject"

@available(iOS 13.0, *)
public struct AnyViewModel<ModelState: Equatable, ViewState, ViewEvents>: ViewModelProtocol {
	
	private let mapState: (ModelState) -> ViewState
	private let mapEvents: (ViewEvents, ModelState) -> AnyPublisher<Action, Never>
	
	public init(state: @escaping (ModelState) -> ViewState, events: @escaping (ViewEvents, ModelState) -> AnyPublisher<Action, Never>) {
		mapState = state
		mapEvents = events
	}
	
	public init<VM: ViewModelProtocol>(_ viewModel: VM) where VM.ViewState == ViewState, VM.ViewEvents == ViewEvents, VM.ModelState == ModelState {
		mapState = viewModel.map
		mapEvents = viewModel.map
	}
	
	public func map(state: ModelState) -> ViewState {
		mapState(state)
	}
	
	public func map(event: ViewEvents, state: ModelState) -> AnyPublisher<Action, Never> {
		mapEvents(event, state)
	}
	
}

@available(iOS 13.0, *)
extension ViewModelProtocol {
	public var asAny: AnyViewModel<ModelState, ViewState, ViewEvents> {
		AnyViewModel(self)
	}
}
