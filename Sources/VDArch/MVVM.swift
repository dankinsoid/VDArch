import Foundation
import RxSwift
import RxOperators
import ComposableArchitecture

@MainActor
public protocol ViewProtocol {
    
    associatedtype Properties: Equatable
	associatedtype Events
	typealias EventsBuilder = ObservableBuilder<Events>
	var events: Observable<Events> { get }
	func bind(state: StateDriver<Properties>) -> Disposable
}

public protocol ViewModelProtocol {
    
    associatedtype ModelState
    associatedtype ViewState: Equatable
    associatedtype ViewEvents
    associatedtype Action
    
    typealias SendAction = (Action) -> ViewStoreTask
    
    func map(state: ModelState, send: SendAction) -> ViewState
	func map(event: ViewEvents, state: ModelState, send: SendAction) -> Action?
}

extension ViewModelProtocol where ModelState == ViewState {
    public func map(state: ModelState, send: SendAction) -> ViewState { state }
}

extension ViewModelProtocol where ViewEvents == Action {
	public func map(event: ViewEvents, state: ModelState, send: SendAction) -> Action? { event }
}

extension ViewProtocol {
	
    public func bind<VM: ViewModelProtocol>(_ viewModel: VM, in store: Store<VM.ModelState, VM.Action>) -> Disposable where VM.ViewState == Properties, VM.ViewEvents == Events, VM.ModelState: Equatable {
        let send: VM.SendAction = ViewStore(store).send
        let viewStore = ViewStore(store) {
            viewModel.map(state: $0, send: send)
        }
        let driver = viewStore.publisher.asDriver()
		let disposables = bind(StateDriver(driver))
		return Disposables.create([
			disposables,
            events.bind(onNext: { action in
                if let event = viewModel.map(event: action, state: ViewStore(store).state, send: send) {
                    viewStore.send(event)
                }
            })
		])
	}
	
	public func bind<O: ObservableConvertibleType>(_ state: O) -> Disposable where O.Element == Properties {
		Disposables.create([
			bind(state: state.asState())
		])
	}
	
	public func bind<Source: ObservableConvertibleType, Observer: ObserverType>(source: Source, observer: Observer) -> Disposable where Source.Element == Properties, Observer.Element == Events {
		Disposables.create(bind(source), bind(state: source.asState()), events.bind(to: observer))
	}
}

extension ViewProtocol where Self: AnyObject {
	
	public func bind<O: ObservableConvertibleType>(_ state: O) where O.Element == Properties {
		bind(state).disposed(by: Reactive(self).asDisposeBag)
	}
	
	public func set(state: Properties) {
		_propertiesSubject.onNext(state)
	}
	
	private var _propertiesSubject: PublishSubject<Properties> {
		get {
			if let subject = objc_getAssociatedObject(self, &propertiesSubjectKey) as? PublishSubject<Properties> {
				return subject
			}
			let subject = PublishSubject<Properties>()
			objc_setAssociatedObject(self, &propertiesSubjectKey, subject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			bind(subject)
			return subject
		}
		set {}
	}
	
}

private var propertiesSubjectKey = "_propertiesSubject"
private var eventsSubjectKey = "_eventsSubject"
