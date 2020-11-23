//
//  ReFlow.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import VDFlow

public typealias StepAction = Action & FlowPathConvertable

extension FlowPath: Action {}
extension FlowStep: Action {}
extension NodeID: Action where Value == Void {}

extension FlowCoordinator {
	
	public func middleware<State>(as: State.Type) -> Middleware<State> {
		middleware()
	}
	
	public func middleware<State>() -> Middleware<State> {
		return {[weak self] _, _ in
			return { next in
				return { action in
					next(action)
					if let step = action as? StepAction {
						DispatchQueue.main.async {
							guard let self = self else { return }
							self.navigate(to: step)
						}
					}
				}
			}
		}
	}

}
