import Foundation
import Combine
import CombineOperators
import ComposableArchitecture

public protocol ViewProtocol {
    
	associatedtype Properties: Equatable
	associatedtype Events
	associatedtype EventsPublisher: Publisher<Events, Never>
	typealias EventsBuilder = ObservableBuilder<Events, Never>
	@EventsBuilder
	var events: EventsPublisher { get }
	@CancellableBuilder
	func bind(state: StatePublisher<Properties>) -> AnyCancellable
}

public protocol ViewModelProtocol {
    
    associatedtype ModelState
    associatedtype ViewState: Equatable
    associatedtype ViewEvents
    associatedtype Action
    
    func map(state: ModelState) -> ViewState
	func map(event: ViewEvents, state: ModelState) -> Action?
}

extension ViewModelProtocol where ModelState == ViewState {
    public func map(state: ModelState) -> ViewState { state }
}

extension ViewModelProtocol where ViewEvents == Action {
	public func map(event: ViewEvents, state: ModelState) -> Action? { event }
}

extension ViewProtocol {
	
    public func bind<VM: ViewModelProtocol>(_ viewModel: VM, in store: Store<VM.ModelState, VM.Action>) -> AnyCancellable where VM.ViewState == Properties, VM.ViewEvents == Events, VM.ModelState: Equatable {
        let viewStore = ViewStore(store) {
            viewModel.map(state: $0)
        }
        let driver = viewStore.publisher.removeDuplicates().receive(on: RunLoop.main)
        return .create {
            bind(state: StatePublisher(driver))
            events.sink { action in
                if let event = viewModel.map(event: action, state: ViewStore(store).state) {
                    viewStore.send(event)
                }
            }
        }
	}
	
	public func bind(_ state: some Publisher<Properties, Never>) -> AnyCancellable {
      bind(state: state.removeDuplicates().receive(on: RunLoop.main).asState())
	}
	
	public func bind(source: some Publisher<Properties, Never>, observer: some Subscriber<Events, Never>) -> AnyCancellable {
		AnyCancellable(
        		bind(state: source.removeDuplicates().receive(on: RunLoop.main).asState()),
            events.sink {
                observer.receive(completion: $0)
            } receiveValue: {
                _ = observer.receive($0)
            }
        )
	}
}

extension ViewProtocol where Self: AnyObject {
	
	public func set(state: Properties) {
		_propertiesSubject.send(state)
	}
	
	private var _propertiesSubject: PassthroughSubject<Properties, Never> {
		get {
			if let subject = objc_getAssociatedObject(self, &propertiesSubjectKey) as? PassthroughSubject<Properties, Never> {
				return subject
			}
			let subject = PassthroughSubject<Properties, Never>()
			objc_setAssociatedObject(self, &propertiesSubjectKey, subject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			let cancellable = bind(subject)
            objc_setAssociatedObject(self, &disposableKey, cancellable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return subject
		}
		set {}
	}
}

private var propertiesSubjectKey = "_propertiesSubject"
private var disposableKey = "disposableKey"
