#if DEBUG
public let isDebug = true


/// - Example: `(lldb) po debugFastThinking()`
public func debugFastThinking() {
    GameAutomator.debugDuration = 0.0
}
#else
public let isDebug = false
#endif
