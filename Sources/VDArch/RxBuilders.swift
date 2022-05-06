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

public typealias DisposableBuilder = ArrayBuilder<Disposable>
public typealias ObservableBuilder<Element> = ArrayBuilder<Observable<Element>>

extension ArrayBuilder where T: ObservableConvertibleType {
	public static func buildExpression<O: ObservableConvertibleType>(_ expression: O) -> [Observable<T.Element>] where T == Observable<O.Element> {
		[expression.asObservable()]
	}
	
	public static func buildFinalResult<O>(_ component: [T]) -> Observable<O> where T == Observable<O> {
		Observable.merge(component)
	}
}

extension ArrayBuilder where T == Disposable {
	public static func buildFinalResult(_ component: [Disposable]) -> Disposable {
		Disposables.create(component)
	}
}

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
