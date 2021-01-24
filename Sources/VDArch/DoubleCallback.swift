//
//  File.swift
//  
//
//  Created by Данил Войдилов on 21.01.2021.
//

import Foundation

struct DoubleCallback<T> {
	
	let callback: (T) -> Void
	
	func execute(_ callback1: (@escaping (T) -> Void) -> Void, _ callback2: (@escaping (T) -> Void) -> Void) {
		var count = 0
		callback1 { value in
			count += 1
			if count == 2 {
				self.callback(value)
			}
		}
		callback2 { value in
			count += 1
			if count == 2 {
				self.callback(value)
			}
		}
	}
	
}
