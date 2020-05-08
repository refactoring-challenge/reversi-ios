import ReactiveSwift



public protocol AutomatorProgressModelProtocol: class {
    var automatorDidProgress: ReactiveSwift.Property<AutomatorProgressModelState> { get }
    var automatorDidChoice: ReactiveSwift.Signal<AvailableCandidate, Never> { get }

    @discardableResult
    func runAutomatorInThisTurn(for availableCandidate: NonEmptyArray<AvailableCandidate>) -> AutomatorCommandResult

    @discardableResult
    func cancel() -> AutomatorCommandResult
}



public extension AutomatorProgressModelProtocol {
    var automatorProgress: AutomatorProgressModelState { self.automatorDidProgress.value }
}



public class AutomatorProgressModel: AutomatorProgressModelProtocol {
    public private(set) var automatorProgress: AutomatorProgressModelState {
        get { self.automatorDidProgressMutable.value }
        set { self.automatorDidProgressMutable.value = newValue }
    }
    public let automatorDidChoice: ReactiveSwift.Signal<AvailableCandidate, Never>
    public let automatorDidProgress: ReactiveSwift.Property<AutomatorProgressModelState>
    private let automatorDidChoiceObserver: ReactiveSwift.Signal<AvailableCandidate, Never>.Observer
    private let automatorDidProgressMutable: ReactiveSwift.MutableProperty<AutomatorProgressModelState>

    private let strategy: CoordinateSelector


    public init(strategy: @escaping CoordinateSelector) {
        self.strategy = strategy

        (self.automatorDidChoice, self.automatorDidChoiceObserver) =
            ReactiveSwift.Signal<AvailableCandidate, Never>.pipe()

        let automatorDidProgressMutable = ReactiveSwift.MutableProperty<AutomatorProgressModelState>(.sleeping)
        self.automatorDidProgressMutable = automatorDidProgressMutable
        self.automatorDidProgress = ReactiveSwift.Property<AutomatorProgressModelState>(automatorDidProgressMutable)
    }


    public func runAutomatorInThisTurn(
        for availableCandidates: NonEmptyArray<AvailableCandidate>
    ) -> AutomatorCommandResult {
        switch self.automatorProgress {
        case .working:
            return .ignored

        case .sleeping:
            let promisedSelectedCoordinate = self.strategy(availableCandidates)

            let cancelToken = AutomatorCancelToken { promisedSelectedCoordinate.cancel() }
            self.automatorProgress = .working(within: availableCandidates, cancelToken: cancelToken)

            promisedSelectedCoordinate
                .then(in: .userInitiated) { [weak self] selected in
                    guard let self = self else { return }
                    self.automatorDidChoiceObserver.send(value: selected)
                    self.automatorProgress = .sleeping
                }

            return .accepted
        }
    }


    public func cancel() -> AutomatorCommandResult {
        switch self.automatorProgress {
        case .sleeping:
            return .ignored

        case .working(within: _, cancelToken: let cancelToken):
            self.automatorProgress = .sleeping
            cancelToken.cancel()
            return .accepted
        }
    }
}



public enum AutomatorCommandResult {
    case accepted
    case ignored
}



public enum AutomatorProgressModelState {
    case working(within: NonEmptyArray<AvailableCandidate>, cancelToken: AutomatorCancelToken)
    case sleeping


    var isWorking: Bool {
        switch self {
        case .sleeping:
            return false
        case .working:
            return true
        }
    }
}



public struct AutomatorCancelToken {
    // NOTE: Hiding canceler to ensure the cancel must be called via the model. If the cancel called by other
    //       components, the progress will become inconsistent.
    fileprivate let cancel: () -> Void


    public init(_ cancel: @escaping () -> Void) {
        self.cancel = cancel
    }


    public static func unsafeInit(_ cancel: @escaping () -> Void) -> AutomatorCancelToken {
        AutomatorCancelToken(cancel
        )
    }
}
