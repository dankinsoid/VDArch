//
//  ReFlow.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import UIKit
import Combine
import CombineCocoa

public protocol StepAction: Action {}

@available(iOS 13.0, *)
public final class FlowCoordinator {
	
	private let stepper = PassthroughSubject<StepAction, Never>()
	private var cancellables = Set<AnyCancellable>()
	
	public init() {}
	
	public func middleware<State>(as: State.Type) -> Middleware<State> {
		middleware()
	}
	
	public func middleware<State>() -> Middleware<State> {
		return {[weak self] _, _ in
			return { next in
				return { action in
					if let step = action as? StepAction {
						DispatchQueue.main.async {
							self?.stepper.send(step)
						}
					}
					next(action)
				}
			}
		}
	}
	
	public func coordinate(with flow: Flow) {
		stepper.sink(receiveValue: {[weak self] in
			if let newContributor = flow.navigate(to: $0) {
				self?.subscribe(contributor: newContributor)
			}
		}).store(in: &cancellables)
	}
	
	private func subscribe(contributor: FlowContributor) {
		stepper.prefix(untilOutputFrom: contributor.finish)
			.sink(receiveValue: {[weak self] in
					if let newContributor = contributor.flow.navigate(to: $0) {
						self?.subscribe(contributor: newContributor)
					}
			}).store(in: &cancellables)
	}
	
}

@available(iOS 13.0, *)
public struct FlowContributor {
	public var flow: Flow
	public var finish: AnyPublisher<Void, Never>
	
	public init<P: Publisher>(flow: Flow, finish: P) {
		self.flow = flow
		self.finish = finish.map { _ in }.skipFailure().prefix(1).any()
	}
	
	public init(flow: Flow, whileAlive root: AnyObject) {
		self = FlowContributor(flow: flow, finish: Reactive(root).deallocated)
	}
	
	public init(flow: Flow, whileDisplayed root: UIViewController) {
		self = FlowContributor(flow: flow, finish: root.cb.dismissed)
	}
	
}

@available(iOS 13.0, *)
public protocol Flow {
	func navigate(to step: StepAction) -> FlowContributor?
}

@available(iOS 13.0, *)
private extension Reactive where Base: UIViewController {
	
	var dismissed: ControlEvent<Void> {
		ControlEvent(events: Publishers.merge {
			self.sentMessage(#selector(Base.viewDidDisappear))
				.filter { [base] _ in base.isBeingDismissed }
				.map { _ in }
			
			self.sentMessage(#selector(Base.didMove))
				.filter({ !($0.first is UIViewController) })
				.map { _ in }
		})
	}
	
}
