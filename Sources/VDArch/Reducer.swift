//
//  Reducer.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import Foundation
import Combine

public typealias Reducer<ReducerStateType> = (_ action: Action, _ state: inout ReducerStateType) -> AnyPublisher<Action, Never>

