import ReactiveSwift



public protocol GameAutomatorProgressModelProtocol: class {
    var automatorDidProgress: ReactiveSwift.Property<GameAutomatorProgress> { get }
}



public extension GameAutomatorProgressModelProtocol {
    var automatorProgress: GameAutomatorProgress { self.automatorDidProgress.value }
}



public protocol GameAutomatorModelProtocol: GameAutomatorProgressModelProtocol {
    var automatorDidChoice: ReactiveSwift.Signal<AvailableCandidate, Never> { get }

    @discardableResult
    func runAutomator(inThisTurn turn: Turn, for availableCandidate: NonEmptyArray<AvailableCandidate>) -> GameAutomatorCommandResult

    @discardableResult
    func cancel() -> GameAutomatorCommandResult
}



public class GameAutomatorModel: GameAutomatorModelProtocol {
    public private(set) var automatorProgress: GameAutomatorProgress {
        get { self.automatorDidProgressMutable.value }
        set { self.automatorDidProgressMutable.value = newValue }
    }
    public let automatorDidChoice: ReactiveSwift.Signal<AvailableCandidate, Never>
    public let automatorDidProgress: ReactiveSwift.Property<GameAutomatorProgress>
    private let automatorDidChoiceObserver: ReactiveSwift.Signal<AvailableCandidate, Never>.Observer
    private let automatorDidProgressMutable: ReactiveSwift.MutableProperty<GameAutomatorProgress>

    private let strategy: CoordinateSelector


    public init(strategy: @escaping CoordinateSelector) {
        self.strategy = strategy

        (self.automatorDidChoice, self.automatorDidChoiceObserver) =
            ReactiveSwift.Signal<AvailableCandidate, Never>.pipe()

        let automatorDidProgressMutable = ReactiveSwift.MutableProperty<GameAutomatorProgress>(.sleeping)
        self.automatorDidProgressMutable = automatorDidProgressMutable
        self.automatorDidProgress = ReactiveSwift.Property<GameAutomatorProgress>(automatorDidProgressMutable)
    }


    public func runAutomator(
        inThisTurn turn: Turn,
        for availableCandidates: NonEmptyArray<AvailableCandidate>
    ) -> GameAutomatorCommandResult {
        switch self.automatorProgress {
        case .thinking:
            return .ignored

        case .sleeping:
            let promisedSelectedCoordinate = self.strategy(availableCandidates)

            let cancelToken = GameAutomatorCancelToken { promisedSelectedCoordinate.cancel() }
            self.automatorProgress = .thinking(on: turn, within: availableCandidates, cancelToken: cancelToken)

            promisedSelectedCoordinate
                .then(in: .userInitiated) { [weak self] selected in
                guard let self = self else { return }
                self.automatorDidChoiceObserver.send(value: selected)
                self.automatorProgress = .sleeping
            }

            return .accepted
        }
    }


    public func cancel() -> GameAutomatorCommandResult {
        switch self.automatorProgress {
        case .sleeping:
            return .ignored

        case .thinking(on: _, within: _, cancelToken: let cancelToken):
            self.automatorProgress = .sleeping
            cancelToken.cancel()
            return .accepted
        }
    }
}



public enum GameAutomatorCommandResult {
    case accepted
    case ignored
}



public enum GameAutomatorProgress {
    case thinking(on: Turn, within: NonEmptyArray<AvailableCandidate>, cancelToken: GameAutomatorCancelToken)
    case sleeping


    public var turnThinking: Turn? {
        switch self {
        case .sleeping:
            return nil
        case .thinking(on: let turn, within: _, cancelToken: _):
            return turn
        }
    }
}



public struct GameAutomatorCancelToken {
    // NOTE: Hiding canceler to ensure the cancel must be called via the model. If the cancel called by other
    //       components, the progress will become inconsistent.
    fileprivate let cancel: () -> Void


    public init(_ cancel: @escaping () -> Void) {
        self.cancel = cancel
    }


    public static func unsafeInit(_ cancel: @escaping () -> Void) -> GameAutomatorCancelToken {
        GameAutomatorCancelToken(cancel
        )
    }
}
