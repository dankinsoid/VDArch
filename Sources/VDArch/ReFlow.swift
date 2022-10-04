import ComposableArchitecture

@MainActor
public final class FlowCoordinator<Step> {
    
    private let navigate: (Step) -> Void
	
    public init<F: Flow>(flow: F) where F.Step == Step {
        navigate = flow.navigate
    }
	
    public func navigate(to step: Step) {
        navigate(step)
    }
    
    public nonisolated func effect<A>(to step: Step) -> Effect<A, Never> {
        .fireAndForget { [self] in
            await navigate(to: step)
        }
    }
}

public protocol Flow {
    associatedtype Step
    
	func navigate(to step: Step)
}
