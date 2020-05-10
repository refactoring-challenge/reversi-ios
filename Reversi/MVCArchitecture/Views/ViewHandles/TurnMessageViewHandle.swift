import UIKit
import ReversiCore



public protocol TurnMessageViewHandleProtocol {
    func apply(message: TurnMessage)
}



public enum TurnMessage {
    case inPlay(turn: Turn)
    case completed(result: GameResult)
}



public class TurnMessageViewHandle: TurnMessageViewHandleProtocol {
    private let messageLabel: UILabel
    private let messageDiskView: DiskView
    private let messageDiskSizeConstraint: NSLayoutConstraint
    private let messageDiskOriginalSize: CGFloat



    public init(messageLabel: UILabel, messageDiskView: DiskView, messageDiskViewConstraint: NSLayoutConstraint) {
        self.messageLabel = messageLabel
        self.messageDiskView = messageDiskView
        self.messageDiskSizeConstraint = messageDiskViewConstraint
        self.messageDiskOriginalSize = messageDiskSizeConstraint.constant
    }


    public func apply(message: TurnMessage) {
        switch message {
        case .inPlay(turn: let turn):
            self.messageDiskView.disk = turn.disk
            self.messageLabel.text = "'s turn"
            self.messageDiskSizeConstraint.constant = self.messageDiskOriginalSize
        case .completed(result: .win(who: let turn)):
            self.messageDiskView.disk = turn.disk
            self.messageLabel.text = " won"
            self.messageDiskSizeConstraint.constant = self.messageDiskOriginalSize
        case .completed(result: .draw):
            self.messageLabel.text = "Tied"
            self.messageDiskSizeConstraint.constant = 0
        }
    }
}