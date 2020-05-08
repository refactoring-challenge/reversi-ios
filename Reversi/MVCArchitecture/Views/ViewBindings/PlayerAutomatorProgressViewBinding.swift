import ReversiCore
import ReactiveSwift



public class PlayerAutomatorProgressViewBinding {
    private let viewHandle: PlayerAutomatorProgressViewHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing playerAutomatorProgressModel: AutomatorProgressModelProtocol,
        updating viewHandle: PlayerAutomatorProgressViewHandleProtocol
    ) {
        self.viewHandle = viewHandle

        playerAutomatorProgressModel.automatorDidProgress
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] automatorProgress in
                guard let self = self else { return }
                switch automatorProgress {
                case .working(for: .first):
                    self.viewHandle.applyFirstPlayerAutomator(inProgress: true)
                    self.viewHandle.applySecondPlayerAutomator(inProgress: false)
                case .working(for: .second):
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