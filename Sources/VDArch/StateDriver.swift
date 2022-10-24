import RxSwift
import RxCocoa
import RxOperators

@dynamicMemberLookup
public struct StateDriver<Element>: ObservableType {
	private let driver: Driver<Element>
	
	public init(_ driver: Driver<Element>) {
		self.driver = driver
	}
	
	public init(just: Element) {
		self.driver = Single.just(just).asDriver(onErrorDriveWith: .never())
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> StateDriver<T> {
		return map { $0[keyPath: keyPath] }
	}
	
	public func map<T>(_ selector: @escaping (Element) -> T) -> StateDriver<T> {
		return StateDriver<T>(driver.map(selector))
	}
	
	public func compactMap<T>(_ selector: @escaping (Element) -> T?) -> StateDriver<T> {
		return StateDriver<T>(asObservable().compactMap(selector).asDriver())
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Element == Observer.Element {
		return driver.asObservable().subscribe(observer)
	}
	
	public func asObservable() -> Observable<Element> {
		return driver.asObservable()
	}
	
}

extension StateDriver where Element: Equatable {
	
	public func skipEqual() -> StateDriver {
		StateDriver(driver.distinctUntilChanged())
	}
}

extension StateDriver {
	
	public subscript<A, T>(dynamicMember keyPath: KeyPath<A, T>) -> StateDriver<T?> where A? == Element {
        return map { $0?[keyPath: keyPath] }
	}
	
	public subscript<A, T>(dynamicMember keyPath: KeyPath<A, T?>) -> StateDriver<T?> where A? == Element {
		return map { $0?[keyPath: keyPath] }
	}
	
}

extension StateDriver where Element == Void {
	
	public func map<T>(_ selector: @escaping () -> T) -> StateDriver<T> {
		return StateDriver<T>(driver.map(selector))
	}
	
}

extension StateDriver {
	
	public func skipEqual<E: Equatable>(by keyPath: KeyPath<Element, E>) -> StateDriver {
		StateDriver(driver.distinctUntilChanged({ $0[keyPath: keyPath] }))
	}
	
	public func skipEqual<E: Equatable>(_ comparor: @escaping (Element) -> (E)) -> StateDriver {
		StateDriver(driver.distinctUntilChanged(comparor))
	}
	
}

extension ObservableConvertibleType {
	
	public func asState() -> StateDriver<Element> {
		StateDriver(asDriver(onErrorDriveWith: .never()))
	}
	
}

@MainActor
public func =><V: ViewProtocol, O: ObservableConvertibleType>(_ lhs: O, _ rhs: Reactive<V>) -> Disposable where O.Element == V.Properties {
	rhs.base.bind(lhs)
}
