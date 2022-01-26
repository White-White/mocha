//
//  BaseInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

protocol Interpreter {
    init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource)
    var numberOfTranslationItems: Int { get }
    func translationItem(at index: Int) -> TranslationItem
}

class BaseInterpreter<Payload>: Interpreter {
    
    let data: DataSlice
    let is64Bit: Bool
    weak var machoSearchSource: MachoSearchSource!
    var shouldPreload: Bool { false }
    
    private let preloadingLock = NSRecursiveLock()
    private let preloadingQueue: DispatchQueue = DispatchQueue.global()
    private var hasPreloaded = false
    private var payloadInside: Payload?
    
    var payload: Payload {
        let ret: Payload
        self.preloadingLock.lock()
        if let payload = self.payloadInside {
            ret = payload
        } else {
            let payload = self.generatePayload()
            self.payloadInside = payload
            ret = payload
        }
        self.preloadingLock.unlock()
        return ret
    }
    
    required init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
        self.data = data
        self.is64Bit = is64Bit
        self.machoSearchSource = machoSearchSource
        self.preloadIfNeeded()
    }
    
    private func preloadIfNeeded() {
        guard self.shouldPreload else { return }
        self.preloadingQueue.async {
            self.preloadingLock.lock()
            guard !self.hasPreloaded else {
                self.preloadingLock.unlock()
                return
            }
            let tick = Utils.tick(String(describing: self))
            self.payloadInside = self.generatePayload()
            Utils.tock(tick)
            self.hasPreloaded = true
            self.preloadingLock.unlock()
        }
    }
    
    func generatePayload() -> Payload {
        fatalError() // must override
    }
    
    func translationItem(at index: Int) -> TranslationItem {
        fatalError()
    }
    
    var numberOfTranslationItems: Int {
        fatalError()
    }
}

class AnonymousInterpreter: BaseInterpreter<AnonymousInterpreter.Dummy> {
    
    struct Dummy {}
    
    var description: String { "Unknown Data" }
    var explanation: String { "Don't know how to interprete these bytes yet." }
    
    override func generatePayload() -> Dummy {
        return Dummy()
    }
    
    override var numberOfTranslationItems: Int {
        return 1
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        return TranslationItem(sourceDataRange: nil,
                               content: TranslationItemContent(description: description, explanation: explanation))
    }
}

class CodeInterpreter: AnonymousInterpreter {
    override var description: String { "Code" }
    override var explanation: String { "This part of the macho file is your machine code. Hopper.app is a better tool for viewing it." }
}
