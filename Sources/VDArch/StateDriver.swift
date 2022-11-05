import Combine
import CombineCocoa
import CombineOperators

@dynamicMemberLookup
public struct StateDriver<Output>: Publisher {
    public typealias Failure = Never
	private let driver: Driver<Output>
	
	public init(_ driver: Driver<Output>) {
		self.driver = driver
	}
	
	public init(just: Output) {
		self.driver = Just(just).asDriver()
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StateDriver<T> {
        map { $0[keyPath: keyPath] }
	}
	
	public func map<T>(_ selector: @escaping (Output) -> T) -> StateDriver<T> {
        StateDriver<T>(driver.publisher.map(selector).asDriver())
	}
	
	public func compactMap<T>(_ selector: @escaping (Output) -> T?) -> StateDriver<T> {
        StateDriver<T>(driver.publisher.compactMap(selector).asDriver())
	}
	
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        driver.receive(subscriber: subscriber)
    }
}

extension StateDriver where Output: Equatable {
	
	public func skipEqual() -> StateDriver {
        StateDriver(driver.removeDuplicates().asDriver())
	}
}

extension StateDriver {
	
	public subscript<A, T>(dynamicMember keyPath: KeyPath<A, T>) -> StateDriver<T?> where A? == Output {
        map { $0?[keyPath: keyPath] }
	}
	
    public subscript<A, T>(dynamicMember keyPath: KeyPath<A, T?>) -> StateDriver<T?> where A? == Output {
        map { $0?[keyPath: keyPath] }
    }
}

extension StateDriver where Output == Void {
	
	public func map<T>(_ selector: @escaping () -> T) -> StateDriver<T> {
        StateDriver<T>(driver.publisher.map(selector).asDriver())
	}
}

extension StateDriver {
	
	public func skipEqual<E: Equatable>(by keyPath: KeyPath<Output, E>) -> StateDriver {
        skipEqual { $0[keyPath: keyPath] == $1[keyPath: keyPath] }
	}
	
	public func skipEqual(_ comparor: @escaping (Output, Output) -> (Bool)) -> StateDriver {
        StateDriver(driver.publisher.removeDuplicates(by: comparor).asDriver())
	}
	
}

extension Publisher {
	
	public func asState() -> StateDriver<Output> {
		StateDriver(asDriver())
	}
	
}

public func =><V: ViewProtocol>(_ lhs: some Publisher<V.Properties, Never>, _ rhs: Reactive<V>) -> AnyCancellable {
	rhs.base.bind(lhs)
}
