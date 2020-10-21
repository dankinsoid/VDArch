//
//  UIKit++.swift
//  VDArch
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import UIKit

extension UIViewController {
	
	public var step: StepAction? {
		get {
			(objc_getAssociatedObject(self, &stepKey) as? StepWrapper)?.step
		}
		set {
			objc_setAssociatedObject(self, &stepKey, newValue.map(StepWrapper.init), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
	
}

private var stepKey = "PresentableStepKey"

fileprivate final class StepWrapper {
	let step: StepAction
	
	init(_ step: StepAction) {
		self.step = step
	}
}
