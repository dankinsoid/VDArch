//
//  File.swift
//  
//
//  Created by Данил Войдилов on 22.02.2021.
//

import Foundation
import VDBuilders
import RxSwift

public struct DisposableCreater: ArrayInitable {
	public static func create(from: [Disposable]) -> Disposable {
		Disposables.create(from)
	}
}

extension Observable: ArrayInitable {
	public typealias Builder = ObservableBuilder<Element>
	public static func create(from: [Observable]) -> Observable {
		Observable.merge(from)
	}
}

public typealias DisposableBuilder = ComposeBuilder<DisposableCreater>
public typealias ObservableBuilder<Element> = ComposeBuilder<Observable<Element>>


extension Disposables {
	
	public static func build(@DisposableBuilder _ builder: () -> Disposable) -> Disposable {
		builder()
	}
}

extension Observable {
	
	public static func merge(@Builder _ builder: () -> Observable) -> Observable {
		builder()
	}
	
}
