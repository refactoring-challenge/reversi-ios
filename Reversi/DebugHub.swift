import UIKit
import ReversiCore



#if DEBUG
/// - Example: `(lldb) po printDebugInfo()`
public func printDebugInfo() {
    guard let composer = debugViewController()?.composer else {
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


/// - Example: `(lldb) po debugFastAll()`
public func debugFastAll() {
    debugFastAnimation()
    debugFastThinking()
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
    debugViewController()?.composer?.modelTracker
}


public func debugViewController() -> ViewController? {
    UIApplication.shared.windows
        .flatMap { window -> [ViewController] in
        guard let viewController = window.rootViewController as? ViewController else { return [] }
        return [viewController]
    }
        .first
}
#endif
