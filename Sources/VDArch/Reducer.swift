//
//  Reducer.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Combine

public protocol ReducerType {
    associatedtype State
    associatedtype Event: Action
    func reduce(action: Event, state: inout State) -> AnyPublisher<Action, Never>
}

public typealias Reducer<ReducerStateType, Actions: Publisher> = (_ action: Action, _ state: inout ReducerStateType) -> Actions where Actions.Output == Action, Actions.Failure == Never
