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

public protocol StepAction: Action {
	func navigate(coordinator: FlowCoordinator)
}

extension FlowPath: StepAction {
	public func navigate(coordinator: FlowCoordinator) {
		coordinator.navigate(to: self)
	}
}

extension FlowPoint: StepAction {
	public func navigate(coordinator: FlowCoordinator) {
		coordinator.navigate(to: self)
	}
}

extension FlowID: Action where Value == Void {}

extension FlowID: StepAction where Value == Void {
	public func navigate(coordinator: FlowCoordinator) {
		coordinator.navigate(to: self)
	}
}

extension FlowMove: StepAction {
	public func navigate(coordinator: FlowCoordinator) {
		coordinator.navigate(to: self)
	}
}

extension StepAction where Self: RawRepresentable, RawValue == String {
	public func navigate(coordinator: FlowCoordinator) {
		coordinator.navigate(to: self)
	}
}

extension FlowCoordinator {
	
	public func middleware<State>(as: State.Type) -> Middleware<State> {
		middleware()
	}
	
	public func middleware<State>() -> Middleware<State> {
		return {[weak self] _, _ in
			return { next in
				return { action in
					if let step = action as? StepAction {
						DispatchQueue.main.async {
							guard let self = self else { return }
							step.navigate(coordinator: self)
						}
					}
					next(action)
				}
			}
		}
	}

}
