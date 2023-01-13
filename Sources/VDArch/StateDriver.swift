import Combine
import CombineCocoa
import CombineOperators

@available(iOS 13.0, *)
@available(iOS, deprecated, message: "use StatePublisher")
public typealias StateDriver<T> = StatePublisher<T>

@available(iOS 13.0, *)
@dynamicMemberLookup
public struct StatePublisher<Output>: Publisher {
    
	public typealias Failure = Never
  public let upstream: AnyPublisher<Output, Never>
	
	public init<P: Publisher>(_ publisher: P) where P.Output == Output {
		self.upstream = publisher.skipFailure().any()
	}
	
	public init(state: StatePublisher<Output>) {
		self.upstream = state.upstream
	}
	
	public init(just: Output) {
		self = StatePublisher(Just(just))
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> StatePublisher<T> {
        map { $0[keyPath: keyPath] }
	}
	
	public func map<T>(_ selector: @escaping (Output) -> T) -> StatePublisher<T> {
        upstream.map(selector).asState()
	}
	
	public func compactMap<T>(_ selector: @escaping (Output) -> T?) -> StatePublisher<T> {
        upstream.compactMap(selector).asState()
	}
	
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        upstream.receive(subscriber: subscriber)
    }
}

extension StatePublisher where Output: Equatable {
	
	public func skipEqual() -> StatePublisher {
      StatePublisher(upstream.removeDuplicates())
	}
}

extension StatePublisher {
	
    public func asState() -> StatePublisher<Output> {
        self
    }

    public subscript<A, T>(dynamicMember keyPath: KeyPath<A, T?>) -> StatePublisher<T?> where A? == Output {
        map { $0?[keyPath: keyPath] }
    }
}

@available(iOS 13.0, *)
extension StatePublisher where Output == Void {
	
	public func map<T>(_ selector: @escaping () -> T) -> StatePublisher<T> {
    upstream.map(selector).asState()
	}
}

extension StatePublisher {
	
	public func skipEqual<E: Equatable>(by keyPath: KeyPath<Output, E>) -> StatePublisher {
    skipEqual { $0[keyPath: keyPath] == $1[keyPath: keyPath] }
	}
	
	public func skipEqual(_ comparator: @escaping (Output, Output) -> (Bool)) -> StatePublisher {
    upstream.removeDuplicates(by: comparator).asState()
	}
}

extension Publisher {
	
	public func asState() -> StatePublisher<Output> {
      StatePublisher(self)
	}
}

public func =><V: ViewProtocol>(_ lhs: some Publisher<V.Properties, Never>, _ rhs: Reactive<V>) -> AnyCancellable {
	rhs.base.bind(lhs)
}
