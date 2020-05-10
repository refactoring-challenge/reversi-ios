import UIKit
import ReversiCore



public protocol GameAutomatorProgressViewHandleProtocol {
    func applyFirstPlayerAutomator(inProgress: Bool)
    func applySecondPlayerAutomator(inProgress: Bool)
}



public class GameAutomatorProgressViewHandle: GameAutomatorProgressViewHandleProtocol {
    private let firstActivityIndicator: UIActivityIndicatorView
    private let secondActivityIndicator: UIActivityIndicatorView


    init(
        firstActivityIndicator: UIActivityIndicatorView,
        secondActivityIndicator: UIActivityIndicatorView
    ) {
        self.firstActivityIndicator = firstActivityIndicator
        self.secondActivityIndicator = secondActivityIndicator
    }


    public func applyFirstPlayerAutomator(inProgress: Bool) {
        if inProgress {
            self.firstActivityIndicator.startAnimating()
        }
        else {
            self.firstActivityIndicator.stopAnimating()
        }
    }


    public func applySecondPlayerAutomator(inProgress: Bool) {
        if inProgress {
            self.secondActivityIndicator.startAnimating()
        }
        else {
            self.secondActivityIndicator.stopAnimating()
        }
    }
}