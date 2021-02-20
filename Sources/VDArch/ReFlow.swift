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

public protocol StepAction: Action {}

public final class FlowCoordinator {
	
	private let stepper = PublishRelay<StepAction>()
	private let disposeBag = DisposeBag()
	
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
							self?.stepper.accept(step)
						}
					}
					next(action)
				}
			}
		}
	}
	
	public func coordinate(with flow: Flow) {
		stepper.subscribe(
			onNext: {[weak self] in
				if let newContributor = flow.navigate(to: $0) {
					self?.subscribe(contributor: newContributor)
				}
			}
		)
		.disposed(by: disposeBag)
	}
	
	private func subscribe(contributor: FlowContributor) {
		stepper.take(until: contributor.finish.asObservable())
			.subscribe(
				onNext: {[weak self] in
					if let newContributor = contributor.flow.navigate(to: $0) {
						self?.subscribe(contributor: newContributor)
					}
				}
			)
			.disposed(by: disposeBag)
	}
	
}

public struct FlowContributor {
	public var flow: Flow
	public var finish: Single<Void>
	
	public init(flow: Flow, finish: Single<Void>) {
		self.flow = flow
		self.finish = finish
	}
	
	public init(flow: Flow, whileAlive root: AnyObject) {
		self = FlowContributor(flow: flow, finish: Reactive(root).deallocated.asSingle())
	}
	
	public init(flow: Flow, whileDisplayed root: UIViewController) {
		self = FlowContributor(flow: flow, finish: root.rx.dismissed.take(1).asSingle())
	}
	
}

public protocol Flow {
	func navigate(to step: StepAction) -> FlowContributor?
}

private extension Reactive where Base: UIViewController {
	
	var dismissed: ControlEvent<Void> {
		let dismissedSource = self.sentMessage(#selector(Base.viewDidDisappear))
			.filter { [base] _ in base.isBeingDismissed }
			.map { _ in }
		
		let movedToParentSource = self.sentMessage(#selector(Base.didMove))
			.filter({ !($0.first is UIViewController) })
			.map { _ in }
		
		return ControlEvent(events: Observable.merge(dismissedSource, movedToParentSource, deallocated))
	}
	
}
