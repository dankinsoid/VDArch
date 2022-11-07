import Foundation
import Combine
import CombineCocoa
import CombineOperators
import ComposableArchitecture

public func =>><V: ViewProtocol>(_ lhs: some Publisher<V.Properties, Never>, _ rhs: Reactive<V>?) -> AnyCancellable {
	rhs?.base.bind(lhs.removeDuplicates()) ?? AnyCancellable()
}

public func =>><Element, O: Subscriber>(_ lhs: StateDriver<Element>, _ rhs: O?) where O.Input == Element?, Element: Equatable, O.Failure == Never {
	guard let rhs = rhs else { return }
    return lhs.skipEqual().map { $0 }.subscribe(rhs)
}
