//
//  RxQueue.swift
//  VDKitFix
//
//  Created by Данил Войдилов on 11.01.2021.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public final class CombineQueue<Output>: Subject {
	public typealias Failure = Never
	
	@Synchronized private var queue: [Output] = []
	@Synchronized private var isPaused = false
	private let subject = PassthroughSubject<Output, Never>()
	
	public init() {}
	
	public func send(actions: Output...) {
		self.send(actions)
	}
	
	public func send(_ actions: [Output]) {
		send(actions: actions)
	}
	
	public func sendFirst(_ action: Output) {
		send(actions: [action], asFirst: true)
	}
	
	private func send(actions: [Output], asFirst: Bool = false) {
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
			subject.send(actions[i])
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
	
	public func send(_ value: Output) {
		send(actions: value)
	}
	
	public func send(completion: Subscribers.Completion<Failure>) {}
	
	public func send(subscription: Subscription) {
		subject.send(subscription: subscription)
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
		subject.receive(subscriber: subscriber)
	}
	
}
