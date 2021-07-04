//
//  MVVM.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine
import CombineCocoa
import CombineOperators

public typealias ActionPublisher = AnyPublisher<Action, Never>

@available(iOS 13.0, *)
public protocol ViewProtocol {
	associatedtype Properties
	associatedtype Events
	typealias EventsBuilder = MergeBuilder<Events, Never>
	typealias EventsPublisher = AnyPublisher<Events, Never>
	typealias PropertiesSubscriber = AnySubscriber<Properties, Never>
	var properties: PropertiesSubscriber { get }
	var events: EventsPublisher { get }
	var cancelBinding: Single<Void, Never> { get }
	
	func bind(state: StateSignal<Properties>)
}

extension ViewProtocol where Self: AnyObject {
	public var cancelBinding: Single<Void, Never> {
		Reactive(self).deallocated.asSingle()
	}
}

@available(iOS 13.0, *)
public protocol ViewModelProtocol {
	associatedtype ModelState: Equatable
	associatedtype ViewState
	associatedtype ViewEvents
	
	func map(state: ModelState) -> ViewState
	func map(event: ViewEvents, state: ModelState) -> ActionPublisher
}

@available(iOS 13.0, *)
extension ViewModelProtocol where ModelState == ViewState {
	public func map(state: ModelState) -> ViewState { state }
}

@available(iOS 13.0, *)
extension ViewModelProtocol where ViewEvents: Action {
	public func map(event: ViewEvents, state: ModelState) -> ActionPublisher { Just(event).any() }
}

@available(iOS 13.0, *)
extension ViewProtocol {
	
	@discardableResult
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>, getter: @escaping (State) -> VM.ModelState) -> Cancellable where VM.ViewState == Properties, VM.ViewEvents == Events {
		let cancellable = CancellablePublisher()
		let cancel: Single<Void, Never> = cancellable.merge(with: cancelBinding).share().asSingle()
		let source = store.cb.prefix(untilOutputFrom: cancel).map(getter).skipEqual()
		let signal = source.map { viewModel.map(state: $0) }.asState()
		signal.subscribe(properties)
		bind(state: signal)
		events.prefix(untilOutputFrom: cancel).flatMap {[weak store] event -> AnyPublisher<Action, Never> in
			guard let state = store?.state else { return Empty(completeImmediately: false).any() }
			return viewModel.map(event: event, state: getter(state)).skipFailure().any()
		}
		.subscribe(store.cb.dispatcher)
		return cancellable
	}
	
	@discardableResult
	public func bind<VM: ViewModelProtocol, MS: StateType, VS: StateType>(_ viewModel: VM, modelStore: Store<MS>, viewStore: Store<VS>, getter: @escaping (MS, VS) -> VM.ModelState) -> Cancellable where VM.ViewState == Properties, VM.ViewEvents == Events {
		let cancellable = CancellablePublisher()
		let cancel: Single<Void, Never> = cancellable.merge(with: cancelBinding).share().asSingle()
		let source: AnyPublisher<VM.ModelState, Never>
		if viewStore === modelStore, VM.self == MS.self {
			source = modelStore.cb.prefix(untilOutputFrom: cancel).map { getter($0, $0 as! VS) }.skipEqual().any()
		} else {
			source = modelStore.cb.prefix(untilOutputFrom: cancel).combineLatest(viewStore.cb).map(getter).skipEqual().any()
		}
		let signal = source.map { viewModel.map(state: $0) }.asState()
		signal.subscribe(properties)
		bind(state: signal)
		
		let cbEvents = events.skipFailure().flatMap {[weak viewStore, weak modelStore] event -> AnyPublisher<Action, Never> in
			guard let model = modelStore?.state, let view = viewStore?.state else { return Empty<Action, Never>(completeImmediately: false).any() }
			return viewModel.map(event: event, state: getter(model, view)).any()
		}
		.prefix(untilOutputFrom: cancel)
		.share()
		
		cbEvents.subscribe(viewStore.cb.dispatcher)
		if modelStore !== viewStore {
			cbEvents.subscribe(modelStore.cb.dispatcher)
		}
		return cancellable
	}
	
	@discardableResult
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>, at keyPath: KeyPath<State, VM.ModelState>) -> Cancellable where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] })
	}
	
	@discardableResult
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>, at keyPath: KeyPath<State, VM.ModelState?>, or value: VM.ModelState) -> Cancellable where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] ?? value })
	}
	
	@discardableResult
	public func bind<VM: ViewModelProtocol, State: StateType>(_ viewModel: VM, in store: Store<State>) -> Cancellable where VM.ViewState == Properties, VM.ViewEvents == Events, VM.ModelState == State {
		bind(viewModel, in: store, getter: { $0 })
	}
	
	public func bind<O: Publisher>(_ state: O) where O.Output == Properties {
		let asState = state.asState()
		asState.subscribe(properties)
		bind(state: asState)
	}
	
	public func bind<Source: Publisher, Observer: Subscriber>(source: Source, observer: Observer) where Source.Output == Properties, Observer.Input == Events {
		let cancel = cancelBinding.share()
		bind(source.prefix(untilOutputFrom: cancel))
		events.prefix(untilOutputFrom: cancel).subscribe(observer.ignoreFailure())
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
