//
//  ActionQueue.swift
//  VDKitFix
//
//  Created by Данил Войдилов on 11.01.2021.
//

import Foundation
import Combine

@available(iOS 13.0, *)
private var queues: [String: CombineQueue<Action>] = [:]

@available(iOS 13.0, *)
public enum ActionQueue {
	
	private static let lock = NSRecursiveLock()
	
	public static subscript(_ key: String) -> CombineQueue<Action> {
		guard let queue = queues[key] else {
			let q = CombineQueue<Action>()
			lock.lock()
			queues[key] = q
			lock.unlock()
			return q
		}
		return queue
	}
	
	public static subscript<R: RawRepresentable>(_ key: R) -> CombineQueue<Action> where R.RawValue == String {
		ActionQueue[key.rawValue]
	}
	
}
