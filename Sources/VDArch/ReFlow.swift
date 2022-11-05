import ComposableArchitecture

public struct FlowCoordinator<Step> {
    
    private let navigate: @MainActor (Step) -> Void
	
    public init<F: Flow>(flow: F) where F.Step == Step {
        navigate = flow.navigate
    }
    
    public init(_ navigate: @escaping @MainActor (Step) -> Void) {
        self.navigate = navigate
    }
	
    @MainActor
    public func navigate(to step: Step) {
        navigate(step)
    }
    
    public func effect<A>(to step: Step) -> Effect<A, Never> {
        .fireAndForget { [self] in
            await navigate(to: step)
        }
    }
    
    public func pullback<S>(_ transform: @escaping (S) -> Step) -> FlowCoordinator<S> {
        FlowCoordinator<S> { [navigate] in
            navigate(transform($0))
        }
    }
}

@MainActor
public protocol Flow {
    associatedtype Step
    
	func navigate(to step: Step)
}
