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

@available(iOS 13.0, *)
public protocol ViewProtocol {
	associatedtype Properties
	associatedtype Events
	typealias EventsBuilder = MergeBuilder<Events, Never>
	typealias EventsPublisher = AnyPublisher<Events, Never>
	typealias PropertiesSubscriber = AnySubscriber<Properties, Never>
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
extension ViewProtocol {
    
    public func effects<VM: ViewModelProtocol>(viewModel: VM) -> MVVMModule<VM, Self> where VM.ViewState == Properties, VM.ViewEvents == Events {
        MVVMModule(view: self, viewModel: viewModel)
    }
	
	public func bind<VM: ViewModelProtocol, State: Equatable>(_ viewModel: VM, in store: Store<State>, getter: @escaping (State) -> VM.State) where VM.ViewState == Properties, VM.ViewEvents == Events {
        store.connect(effects: { effects(viewModel: viewModel).effects(states: $0.map(getter)) })
	}
	
	public func bind<VM: ViewModelProtocol, State: Equatable>(_ viewModel: VM, in store: Store<State>, at keyPath: KeyPath<State, VM.State>) where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] })
	}
	
	public func bind<VM: ViewModelProtocol, State: Equatable>(_ viewModel: VM, in store: Store<State>, at keyPath: KeyPath<State, VM.State?>, or value: VM.State) where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] ?? value })
	}
	
	public func bind<VM: ViewModelProtocol, State>(_ viewModel: VM, in store: Store<State>) where VM.ViewState == Properties, VM.ViewEvents == Events, VM.State == State {
		bind(viewModel, in: store, getter: { $0 })
	}
	
	public func bind<O: Publisher>(_ state: O) where O.Output == Properties {
		bind(state: state.asState())
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
        if let subject = objc_getAssociatedObject(self, &propertiesSubjectKey) as? PassthroughSubject<Properties, Never> {
            return subject
        }
        let subject = PassthroughSubject<Properties, Never>()
        objc_setAssociatedObject(self, &propertiesSubjectKey, subject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        bind(subject)
        return subject
	}
	
}

private var propertiesSubjectKey = "_propertiesSubject"
private var eventsSubjectKey = "_eventsSubject"
