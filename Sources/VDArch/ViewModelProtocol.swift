//
//  File.swift
//  
//
//  Created by Данил Войдилов on 07.08.2021.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public protocol ViewModelProtocol: EffectsType {
    override associatedtype State: Equatable
    associatedtype ViewState
    associatedtype ViewEvents
    
    func map(state: State) -> ViewState
    func map(event: ViewEvents, state: State) -> AnyPublisher<Action, Never>
}

extension ViewModelProtocol where ActionPublisher == AnyPublisher<Action, Never> {
    public func effects<P: Publisher>(states: P) -> ActionPublisher where State == P.Output, P.Failure == Never {
        .empty()
    }
}

@available(iOS 13.0, *)
extension ViewModelProtocol where State == ViewState {
    
    public func map(state: State) -> ViewState { state }
}

@available(iOS 13.0, *)
extension ViewModelProtocol where ViewEvents: Action {
    public func map(event: ViewEvents, state: State) -> AnyPublisher<Action, Never> { Just(event).any() }
}

@available(iOS 13.0, *)
extension ViewModelProtocol {
    public var asAny: AnyViewModel<State, ViewState, ViewEvents> {
        AnyViewModel(self)
    }
}

@available(iOS 13.0, *)
public struct AnyViewModel<State: Equatable, ViewState, ViewEvents>: ViewModelProtocol {
    
    private let mapState: (State) -> ViewState
    private let mapEvents: (ViewEvents, State) -> AnyPublisher<Action, Never>
    private let mapEffects: (AnyPublisher<State, Never>) -> AnyPublisher<Action, Never>
    
    public init(state: @escaping (State) -> ViewState, events: @escaping (ViewEvents, State) -> AnyPublisher<Action, Never>, effects: @escaping (AnyPublisher<State, Never>) -> AnyPublisher<Action, Never>) {
        mapState = state
        mapEvents = events
        mapEffects = effects
    }
    
    public init<VM: ViewModelProtocol>(_ viewModel: VM) where VM.ViewState == ViewState, VM.ViewEvents == ViewEvents, VM.State == State {
        mapState = viewModel.map
        mapEvents = viewModel.map
        mapEffects = { AnyPublisher(viewModel.effects(states: $0)) }
    }
    
    public func map(state: State) -> ViewState {
        mapState(state)
    }
    
    public func map(event: ViewEvents, state: State) -> AnyPublisher<Action, Never> {
        mapEvents(event, state)
    }
    
    public func effects<P: Publisher>(states: P) -> AnyPublisher<Action, Never> where State == P.Output, P.Failure == Never {
        mapEffects(AnyPublisher(states))
    }
}
