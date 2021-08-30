//
//  File.swift
//  
//
//  Created by Данил Войдилов on 07.08.2021.
//

import Foundation
import Combine
import CombineCocoa

@available(iOS 13.0, *)
public struct MVVMModule<ViewModel: ViewModelProtocol, View: ViewProtocol>: EffectsType where View.Properties == ViewModel.ViewState, View.Events == ViewModel.ViewEvents {
    
    public typealias State = ViewModel.State
    public typealias ActionPublisher = AnyPublisher<Action, Never>
    
    public var viewModel: ViewModel
    public var view: View
    
    public init(view: View, viewModel: ViewModel) {
        self.view = view
        self.viewModel = viewModel
    }
    
    public func effects<P: Publisher>(states: P) -> AnyPublisher<Action, Never> where ViewModel.State == P.Output, P.Failure == Never {
        let state = states.removeDuplicates()
        return view.events
            .combineLatest(state)
            .flatMap {
                viewModel.map(event: $0.0, state: $0.1)
            }
            .merge(with: viewModel.effects(states: state))
            .prefix(untilOutputFrom: view.cancelBinding)
            .handleEvents(receiveSubscription: { _ in
                view.bind(
                    state.map(viewModel.map)
                        .prefix(untilOutputFrom: view.cancelBinding)
                        .asState()
                )
            })
            .any()
    }
}

extension MVVMModule: ReducerBaseModule where ViewModel: ReducerBaseModule {
    public func reduceAny(action: Action, state: inout ViewModel.State) -> AnyPublisher<Action, Never> {
        viewModel.reduceAny(action: action, state: &state)
    }
}

extension MVVMModule: ReducerModule where ViewModel: ReducerModule {
    public typealias Event = ViewModel.Event
    
    public func reduce(action: ViewModel.Event, state: inout ViewModel.State) -> AnyPublisher<Action, Never> {
        viewModel.reduce(action: action, state: &state)
    }
}
