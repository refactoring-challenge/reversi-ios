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
                switch automatorProgress {
                case .thinking(in: .first, within: _, cancelToken: _):
                    self.viewHandle.applyFirstPlayerAutomator(inProgress: true)
                    self.viewHandle.applySecondPlayerAutomator(inProgress: false)
                case .thinking(in: .second, within: _, cancelToken: _):
                    self.viewHandle.applyFirstPlayerAutomator(inProgress: false)
                    self.viewHandle.applySecondPlayerAutomator(inProgress: true)
                case .sleeping:
                    self.viewHandle.applyFirstPlayerAutomator(inProgress: false)
                    self.viewHandle.applySecondPlayerAutomator(inProgress: false)
                }
            })
            .start()
    }
}