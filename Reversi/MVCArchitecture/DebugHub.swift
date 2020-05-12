import UIKit
import ReversiCore



#if DEBUG
public let isDebug = true
#else
public let isDebug = false
#endif


/// - Example: `(lldb) po printDebugInfo()`
public func printDebugInfo() {
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


/// - Example: `(lldb) po debugFastAnimation()`
public func debugFastAnimation() {
    animationDuration = 0.01
}


/// - Example: `(lldb) po debugFastThinking()`
public func debugFastThinking() {
    gameAutomatorDuration = 0.0
}


/// - Example: `(lldb) po printModelsHistory()`
public func printModelsHistory() {
    guard let modelsTracker = debugModelsTracker() else { return }
    modelsTracker.printRecentHistory()
}


/// - Example: `(lldb) po printUserDefaults()`
public func printUserDefaults(_ userDefaults: UserDefaults = UserDefaults.standard) {
    dump(userDefaults.dictionaryRepresentation())
}


public func debugModelsTracker() -> ModelTrackerProtocol? {
    debugComposer()?.modelTracker
}


public func debugComposer() -> BoardMVCComposer? {
    (UIApplication.shared.keyWindow?.rootViewController as? ViewController)?.composer
}
