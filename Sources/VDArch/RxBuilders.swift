import Foundation
import Combine

@resultBuilder
public enum CancellableBuilder {
    
    @inlinable
    public static func buildBlock(_ components: AnyCancellable...) -> AnyCancellable {
        AnyCancellable(components)
    }
    
    @inlinable
    public static func buildArray(_ components: [AnyCancellable]) -> AnyCancellable {
        AnyCancellable(components)
    }
    
    @inlinable
    public static func buildEither(first component: AnyCancellable) -> AnyCancellable {
        component
    }
    
    @inlinable
    public static func buildEither(second component: AnyCancellable) -> AnyCancellable {
        component
    }
    
    @inlinable
    public static func buildOptional(_ component: AnyCancellable?) -> AnyCancellable {
        component ?? AnyCancellable()
    }
    
    @inlinable
    public static func buildLimitedAvailability(_ component: AnyCancellable) -> AnyCancellable {
        component
    }
    
    @inlinable
    public static func buildExpression(_ expression: AnyCancellable) -> AnyCancellable {
        expression
    }
    
    @inlinable
    public static func buildExpression(_ expression: any Cancellable) -> AnyCancellable {
        AnyCancellable(expression)
    }
}

@resultBuilder
public enum ObservableBuilder<Output, Failure: Error> {
    
    @inlinable
    public static func buildBlock() -> Empty<Output, Failure> {
        Empty()
    }
    
    @inlinable
    public static func buildArray(_ components: [some Publisher<Output, Failure>]) -> some Publisher<Output, Failure> {
        Publishers.MergeMany(components)
    }
    
    @inlinable
    public static func buildPartialBlock(first content: some Publisher<Output, Failure>) -> some Publisher<Output, Failure> {
        content
    }
    
    @inlinable
    public static func buildPartialBlock(accumulated: some Publisher<Output, Failure>, next: some Publisher<Output, Failure>) -> some Publisher<Output, Failure> {
        accumulated.merge(with: next)
    }
    
    @inlinable
    public static func buildEither(first component: some Publisher<Output, Failure>) -> some Publisher<Output, Failure> {
        component
    }
    
    @inlinable
    public static func buildEither(second component: some Publisher<Output, Failure>) -> some Publisher<Output, Failure> {
        component
    }
    
    @inlinable
    public static func buildOptional<P: Publisher<Output, Failure>>(_ component: P?) -> some Publisher<Output, Failure> {
        component?.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }
    
    @inlinable
    public static func buildLimitedAvailability(_ component: some Publisher<Output, Failure>) -> some Publisher<Output, Failure> {
        component
    }
}

extension AnyCancellable {
    
    static func create(@CancellableBuilder _ create: () -> AnyCancellable) -> AnyCancellable {
        create()
    }
}
