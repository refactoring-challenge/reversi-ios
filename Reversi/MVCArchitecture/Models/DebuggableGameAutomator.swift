import Foundation
import ReversiCore


public var gameAutomatorDuration: TimeInterval = 0


public func debuggableGameAutomator(selector: @escaping CoordinateSelector, duration: TimeInterval) -> CoordinateSelector {
    gameAutomatorDuration = duration
    return { availableCandidates in GameAutomator.delayed(selector: selector, gameAutomatorDuration)(availableCandidates) }
}