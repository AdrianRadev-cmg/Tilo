//
//  DebugLog.swift
//  Tilo
//
//  Debug logging utility - only prints in DEBUG builds
//

import Foundation

/// Debug-only logging function. Prints are stripped from release builds.
/// Usage: debugLog("Message here") or debugLog("Value:", someValue)
@inline(__always)
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    #endif
}
