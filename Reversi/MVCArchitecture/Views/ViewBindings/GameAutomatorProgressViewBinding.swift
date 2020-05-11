import ReversiCore
import ReactiveSwift



public class GameAutomatorProgressViewBinding {
    private let viewHandle: GameAutomatorProgressViewHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing playerAutomatorProgressModel: GameAutomatorProgressModelProtocol,
        updating viewHandle: GameAutomatorProgressViewHandleProtocol
    ) {
        self.viewHandle = viewHandle

        playerAutomatorProgressModel.automatorDidProgress
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] automatorProgress in
                guard let self = self else { return }
                self.viewHandle.apply(inProgress: automatorProgress.turnThinking)
            })
            .start()
    }
}