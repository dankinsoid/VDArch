//
//  File.swift
//  
//
//  Created by Данил Войдилов on 07.08.2021.
//

import Foundation
import Combine

public protocol EffectsType where ActionPublisher.Output == Action, ActionPublisher.Failure == Never {
    associatedtype State: Equatable
    associatedtype ActionPublisher: Publisher = AnyPublisher<Action, Never>
    func effects<P: Publisher>(states: P) -> ActionPublisher where P.Output == State, P.Failure == Never
}

public struct EffectsMap<Base: EffectsType, State: Equatable>: EffectsType {
    var map: (State) -> Base.State
    var base: Base
    
    public func effects<P>(states: P) -> Base.ActionPublisher where P : Publisher, State == P.Output, P.Failure == Never {
        base.effects(states: states.map(map))
    }
}

extension EffectsType {
    public func map<T>(_ map: @escaping (T) -> State) -> EffectsMap<Self, T> {
        EffectsMap(map: map, base: self)
    }
    
    public func map<T>(_ keyPath: KeyPath<T, State>) -> EffectsMap<Self, T> {
        EffectsMap(map: { $0[keyPath: keyPath] }, base: self)
    }
}

extension Store {
    
    public func connect<E: EffectsType>(effects: E) where E.State == State {
        effects.effects(states: cb).subscribe(cb.dispatcher)
    }
    
    public func connect<ActionPublisher: Publisher>(effects: @escaping (AnyPublisher<State, Never>) -> ActionPublisher) where ActionPublisher.Output == Action, ActionPublisher.Failure == Never {
        effects(cb.any()).subscribe(cb.dispatcher)
    }
}
