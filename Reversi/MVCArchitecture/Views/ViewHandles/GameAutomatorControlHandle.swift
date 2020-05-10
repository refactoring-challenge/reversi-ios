import UIKit
import ReversiCore
import ReactiveSwift



public protocol GameAutomatorControlHandleProtocol {
    var availabilitiesDidChange: ReactiveSwift.Signal<GameAutomatorAvailabilities, Never> { get }
    func apply(availabilities: GameAutomatorAvailabilities)
}



public class GameAutomatorControlHandle: GameAutomatorControlHandleProtocol {
    public let availabilitiesDidChange: ReactiveSwift.Signal<GameAutomatorAvailabilities, Never>
    private let availabilitiesDidChangeObserver: ReactiveSwift.Signal<GameAutomatorAvailabilities, Never>.Observer
    private let firstSegmentedControl: UISegmentedControl
    private let secondSegmentedControl: UISegmentedControl


    private let segmentIndexToDisable = 0
    private let segmentIndexToEnable = 1


    public init(firstSegmentedControl: UISegmentedControl, secondSegmentedControl: UISegmentedControl) {
        self.firstSegmentedControl = firstSegmentedControl
        self.secondSegmentedControl = secondSegmentedControl

        (self.availabilitiesDidChange, self.availabilitiesDidChangeObserver) =
            ReactiveSwift.Signal<GameAutomatorAvailabilities, Never>.pipe()

        // BUG11: Forgot observing.
        self.firstSegmentedControl.addTarget(
            self,
            action: #selector(self.segmentedControlDidChange(_:)),
            for: .valueChanged
        )
        self.secondSegmentedControl.addTarget(
            self,
            action: #selector(self.segmentedControlDidChange(_:)),
            for: .valueChanged
        )
    }


    @objc private func segmentedControlDidChange(_ sender: Any) {
        self.availabilitiesDidChangeObserver.send(value: GameAutomatorAvailabilities(
            first: self.firstSegmentedControl.selectedSegmentIndex == segmentIndexToEnable
                ? .enabled
                : .disabled,
            second: self.secondSegmentedControl.selectedSegmentIndex == segmentIndexToEnable
                ? .enabled
                : .disabled
        ))
    }


    public func apply(availabilities: GameAutomatorAvailabilities) {
        switch availabilities.first {
        case .disabled:
            self.firstSegmentedControl.selectedSegmentIndex = segmentIndexToDisable
        case .enabled:
            self.firstSegmentedControl.selectedSegmentIndex = segmentIndexToEnable
        }

        switch availabilities.first {
        case .disabled:
            self.secondSegmentedControl.selectedSegmentIndex = segmentIndexToDisable
        case .enabled:
            self.secondSegmentedControl.selectedSegmentIndex = segmentIndexToEnable
        }
    }
}
