import Foundation
import RxSwift
import RxOperators
import ComposableArchitecture

public protocol ViewProtocol {
    
	associatedtype Properties
	associatedtype Events
	typealias EventsBuilder = ObservableBuilder<Events>
	var events: Observable<Events> { get }
	func bind(state: StateDriver<Properties>) -> Disposable
}

public protocol ViewModelProtocol {
	associatedtype ModelState: Equatable
	associatedtype ViewState
	associatedtype ViewEvents
    associatedtype Action
	
	func map(state: ModelState) -> ViewState
	func map(event: ViewEvents, state: ModelState) -> Observable<Action>
}

extension ViewModelProtocol where ModelState == ViewState {
	public func map(state: ModelState) -> ViewState { state }
}

extension ViewModelProtocol where ViewEvents == Action {
	public func map(event: ViewEvents, state: ModelState) -> Observable<Action> { .just(event) }
}

extension ViewProtocol {
	
    public func bind<VM: ViewModelProtocol, State>(_ viewModel: VM, in store: ViewStore<State, VM.Action>, getter: @escaping (State) -> VM.ModelState) -> Disposable where VM.ViewState == Properties, VM.ViewEvents == Events {
		let source = store.rx.map(getter).skipEqual()
		let driver = source.map { viewModel.map(state: $0) }.asDriver()
		let disposables = bind(StateDriver(driver))
		return Disposables.create([
			disposables,
            events.flatMap {[weak store] event -> Observable<VM.Action> in
				guard let state = store?.state else { return .never() }
				return viewModel.map(event: event, state: getter(state))
			}
			.bind(to: store.rx.dispatcher)
		])
	}
	
    public func bind<VM: ViewModelProtocol, State>(_ viewModel: VM, in store: ViewStore<State, VM.Action>, at keyPath: KeyPath<State, VM.ModelState>) -> Disposable where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] })
	}
	
    public func bind<VM: ViewModelProtocol, State>(_ viewModel: VM, in store: ViewStore<State, VM.Action>, at keyPath: KeyPath<State, VM.ModelState?>, or value: VM.ModelState) -> Disposable where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0[keyPath: keyPath] ?? value })
	}
	
    public func bind<VM: ViewModelProtocol>(_ viewModel: VM, in store: ViewStore<VM.ModelState, VM.Action>) -> Disposable where VM.ViewState == Properties, VM.ViewEvents == Events {
		bind(viewModel, in: store, getter: { $0 })
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

public struct AnyViewModel<ModelState: Equatable, ViewState, ViewEvents, Action>: ViewModelProtocol {
	
	private let mapState: (ModelState) -> ViewState
	private let mapEvents: (ViewEvents, ModelState) -> Observable<Action>
	
	public init(state: @escaping (ModelState) -> ViewState, events: @escaping (ViewEvents, ModelState) -> Observable<Action>) {
		mapState = state
		mapEvents = events
	}
	
    public init<VM: ViewModelProtocol>(_ viewModel: VM) where VM.ViewState == ViewState, VM.ViewEvents == ViewEvents, VM.ModelState == ModelState, VM.Action == Action {
		mapState = viewModel.map
		mapEvents = viewModel.map
	}
	
	public func map(state: ModelState) -> ViewState {
		mapState(state)
	}
	
	public func map(event: ViewEvents, state: ModelState) -> Observable<Action> {
		mapEvents(event, state)
	}
	
}

extension ViewModelProtocol {
	public var asAny: AnyViewModel<ModelState, ViewState, ViewEvents, Action> {
		AnyViewModel(self)
	}
}
