//
//  ActionQueue.swift
//  VDKitFix
//
//  Created by Данил Войдилов on 11.01.2021.
//

import Foundation
import RxSwift

private var queues: [String: RxQueue<Action>] = [:]

public enum ActionQueue {
	
	private static let lock = NSRecursiveLock()
	
	public static subscript(_ key: String) -> RxQueue<Action> {
		guard let queue = queues[key] else {
			let q = RxQueue<Action>()
			lock.lock()
			queues[key] = q
			lock.unlock()
			return q
		}
		return queue
	}
	
	public static subscript<R: RawRepresentable>(_ key: R) -> RxQueue<Action> where R.RawValue == String {
		ActionQueue[key.rawValue]
	}
	
}
