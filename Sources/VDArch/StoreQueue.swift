//
//  StoreQueue.swift
//  VDKitFix
//
//  Created by Данил Войдилов on 11.01.2021.
//

import Foundation

extension DispatchQueue {
	public static let store = DispatchQueue(label: "store_queue", qos: .userInitiated)
}
