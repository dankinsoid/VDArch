//
//  RxQueue.swift
//  VDKitFix
//
//  Created by Данил Войдилов on 11.01.2021.
//

import Foundation
import RxSwift

public final class RxQueue<Element>: ObservableType, ObserverType {
	
	@Synchronized private var queue: [Element] = []
	@Synchronized private var isPaused = false
	private let subject = PublishSubject<Element>()
	
	public init() {}
	
	public func send(_ actions: Element...) {
		self.send(actions)
	}
	
	public func send(_ actions: [Element]) {
		send(actions: actions)
	}
	
	public func sendFirst(_ action: Element) {
		send(actions: [action], asFirst: true)
	}
	
	private func send(actions: [Element], asFirst: Bool = false) {
		guard !actions.isEmpty else { return }
		for i in 0..<actions.count {
			guard !isPaused else {
				if asFirst {
					queue = Array(actions.dropFirst(i)) + queue
				} else {
					queue += Array(actions.dropFirst(i))
				}
				return
			}
			subject.onNext(actions[i])
		}
	}
	
	public func lock() {
		isPaused = true
	}
	
	public func unlock() {
		let array = queue
		queue = []
		send(actions: array)
	}
	
	public func on(_ event: Event<Element>) {
		if case .next(let element) = event {
			send(element)
		}
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Element == Observer.Element {
		subject.subscribe(observer)
	}
	
}

