import Foundation
import Combine
import RxSwift
import RxCocoa
import RxOperators
import ComposableArchitecture

extension ViewStore {
    public var rx: RxStore<ViewState, ViewAction> { RxStore(self) }
}

@dynamicMemberLookup
public struct RxStore<State, Action>: ObservableType {
	public typealias Element = State
	public let base: ViewStore<State, Action>
	
	public var dispatcher: AnyObserver<Action> {
		AnyObserver {[base] in
			guard case .next(let action) = $0 else { return }
            base.send(action)
		}
	}
	
    public init(_ store: ViewStore<State, Action>) {
        base = store
    }
    
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> StoreObservable<State, Action, T> {
		StoreObservable<State, Action, T>(base: base, map: { $0[keyPath: keyPath] })
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where State == Observer.Element {
        let cancellable = base.publisher.sink { state in
            observer.onNext(state)
        }
        return Disposables.create {
            cancellable.cancel()
        }
	}
}

@dynamicMemberLookup
public struct StoreObservable<State, Action, Element>: ObservableType {
    
	public let base: ViewStore<State, Action>
	let map: (State) -> Element
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> StoreObservable<State, Action, T> {
		StoreObservable<State, Action, T>(base: base, map: {[map] in map($0)[keyPath: keyPath] })
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Element == Observer.Element {
        let cancellable = base.publisher.sink { [map] state in
            observer.onNext(map(state))
        }
        return Disposables.create {
            cancellable.cancel()
        }
	}
}

extension Reactive where Base: ViewProtocol {
	
	public var events: Observable<Base.Events> {
		base.events
	}
}

extension Publisher {
    
    func asDriver() -> Driver<Output> {
        Observable.create { observer in
            let cancellable = sink {
                switch $0 {
                case .finished:
                    observer.onCompleted()
                case .failure(let failure):
                    observer.onError(failure)
                }
            } receiveValue: {
                observer.onNext($0)
            }
            return Disposables.create {
                cancellable.cancel()
            }
        }
        .asDriver()
    }
}

public func =>><V: ViewProtocol, O: ObservableConvertibleType>(_ lhs: O, _ rhs: Reactive<V>?) -> Disposable where O.Element == V.Properties {
	rhs?.base.bind(lhs.asObservable().distinctUntilChanged()) ?? Disposables.create()
}

public func =>><Element, O: ObserverType>(_ lhs: StateDriver<Element>, _ rhs: O?) -> Disposable where O.Element == Element?, Element: Equatable {
	guard let rhs = rhs else { return Disposables.create() }
	return lhs.skipEqual() => rhs
}
