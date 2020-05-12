import UIKit
import ReversiCore



#if DEBUG
public let isDebug = true
#else
public let isDebug = false
#endif


/// - Example: `(lldb) po debugInfo()`
public func debugInfo() {
    guard let composer = debugComposer() else {
        print("Debuggable ViewController not found")
        return
    }

    dump([
        "gameWithAutomatorsModelState": composer.animatedGameWithAutomatorsModel.gameWithAutomatorsModelState,
        "boardAnimationState": composer.animatedGameWithAutomatorsModel.boardAnimationState,
        "availabilities": composer.animatedGameWithAutomatorsModel.availabilities,
        "automatorProgress": composer.animatedGameWithAutomatorsModel.automatorProgress,
    ])
}


/// - Example: `(lldb) po printModelsHistory()`
public func printModelsHistory() {
    guard let modelsTracker = debugModelsTracker() else { return }
    modelsTracker.printRecentHistory()
}


public func debugModelsTracker() -> ModelTrackerProtocol? {
    debugComposer()?.modelTracker
}


public func debugComposer() -> BoardMVCComposer? {
    (UIApplication.shared.keyWindow?.rootViewController as? ViewController)?.composer
}
