//
//  TickTock.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/12.
//

import Foundation

class TickTock {
    
    private var enabled: Bool = true
    private var ts: Double = CACurrentMediaTime() * 1000
    
    static func tick() -> TickTock {
        return TickTock()
    }
    
    func tock(_ name: String, threshHold: Double = 1) {
        let nextTs = CACurrentMediaTime() * 1000
        let timeGap = nextTs - ts; ts = nextTs
        guard enabled else { return }
        guard timeGap > threshHold else { return }
        print("\n\(name)'s time usage:")
        print("--- \(timeGap) ms.")
    }
 
    func disable() -> TickTock {
        enabled = false
        return self
    }
    
    func enable() -> TickTock {
        enabled = true
        return self
    }
}
