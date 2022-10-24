import ComposableArchitecture

@MainActor
public struct FlowCoordinator<Step> {
    
    private let navigate: (Step) -> Void
	
    public nonisolated init<F: Flow>(flow: F) where F.Step == Step {
        navigate = flow.navigate
    }
    
    public nonisolated init(_ navigate: @escaping (Step) -> Void) {
        self.navigate = navigate
    }
	
    public func navigate(to step: Step) {
        navigate(step)
    }
    
    public nonisolated func effect<A>(to step: Step) -> Effect<A, Never> {
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
