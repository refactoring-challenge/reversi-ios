import ReversiCore
import UIKit



public protocol DiskCountViewHandleProtocol {
    func apply(diskCount: DiskCount)
}



public class DiskCountViewHandle: DiskCountViewHandleProtocol {
    private let firstPlayerCountLabel: UILabel
    private let secondPlayerCountLabel: UILabel


    public init(
        firstPlayerCountLabel: UILabel,
        secondPlayerCountLabel: UILabel
    ) {
        self.firstPlayerCountLabel = firstPlayerCountLabel
        self.secondPlayerCountLabel = secondPlayerCountLabel
    }


    public func apply(diskCount: DiskCount) {
        self.firstPlayerCountLabel.text = String(diskCount.first)
        self.secondPlayerCountLabel.text = String(diskCount.second)
    }
}