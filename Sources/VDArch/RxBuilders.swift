import Foundation
import RxSwift

@resultBuilder
public enum DisposableBuilder {
    
    @inlinable
    public static func buildBlock(_ components: Disposable...) -> Disposable {
        Disposables.create(components)
    }
    
    @inlinable
    public static func buildArray(_ components: [Disposable]) -> Disposable {
        Disposables.create(components)
    }
    
    @inlinable
    public static func buildEither(first component: Disposable) -> Disposable {
        component
    }
    
    @inlinable
    public static func buildEither(second component: Disposable) -> Disposable {
        component
    }
    
    @inlinable
    public static func buildOptional(_ component: Disposable?) -> Disposable {
        component ?? Disposables.create()
    }
    
    @inlinable
    public static func buildLimitedAvailability(_ component: Disposable) -> Disposable {
        component
    }
}

@resultBuilder
public enum ObservableBuilder<Element> {
    
    @inlinable
    public static func buildBlock(_ components: Observable<Element>...) -> Observable<Element> {
        Observable.merge(components)
    }
    
    @inlinable
    public static func buildArray(_ components: [Observable<Element>]) -> Observable<Element> {
        Observable.merge(components)
    }
    
    @inlinable
    public static func buildEither(first component: Observable<Element>) -> Observable<Element> {
        component
    }
    
    @inlinable
    public static func buildEither(second component: Observable<Element>) -> Observable<Element> {
        component
    }
    
    @inlinable
    public static func buildOptional(_ component: Observable<Element>?) -> Observable<Element> {
        component ?? .empty()
    }
    
    @inlinable
    public static func buildLimitedAvailability(_ component: Observable<Element>) -> Observable<Element> {
        component
    }
    
    @inlinable
    public static func buildExpression<O: ObservableConvertibleType>(_ expression: O) -> Observable<Element> where Element == O.Element {
        expression.asObservable()
    }
}

extension Disposables {
	
	public static func build(@DisposableBuilder _ builder: () -> Disposable) -> Disposable {
		builder()
	}
}

extension Observable {
    
	public static func merge(@ObservableBuilder<Element> _ builder: () -> Observable) -> Observable {
		builder()
	}
}
