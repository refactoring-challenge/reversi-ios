import UIKit
import ReversiCore



public protocol GameAutomatorProgressViewHandleProtocol {
    func apply(inProgress: Turn?)
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


    public func apply(inProgress: Turn?) {
        switch inProgress {
        case .none:
            self.firstActivityIndicator.stopAnimating()
            self.secondActivityIndicator.stopAnimating()
        case .some(.first):
            self.firstActivityIndicator.startAnimating()
            self.secondActivityIndicator.stopAnimating()
        case .some(.second):
            self.firstActivityIndicator.stopAnimating()
            self.secondActivityIndicator.startAnimating()
        }
    }
}