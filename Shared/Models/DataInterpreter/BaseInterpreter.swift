//
//  BaseInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

protocol Interpreter {
    func numberOfTranslationSections() -> Int
    func numberOfTranslationItems(at section: Int) -> Int
    func translationItem(at indexPath: IndexPath) -> TranslationItem
    func defaultSelectedTranslationItem() -> TranslationItem?
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
    
    init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
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
    
    func numberOfTranslationSections() -> Int {
        fatalError()
    }
    
    func numberOfTranslationItems(at section: Int) -> Int {
        fatalError()
    }
    
    func translationItem(at indexPath: IndexPath) -> TranslationItem {
        fatalError()
    }
    
    func defaultSelectedTranslationItem() -> TranslationItem? {
        return self.translationItem(at: .init(item: .zero, section: .zero))
    }
}

class CowardInterpreter: Interpreter {
    
    let description: String
    let explanation: String
    
    init(description: String, explanation: String) {
        self.description = description
        self.explanation = explanation
    }
    
    func numberOfTranslationSections() -> Int {
        return 1
    }
    
    func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    func translationItem(at indexPath: IndexPath) -> TranslationItem {
        return TranslationItem(sourceDataRange: nil,
                               content: TranslationItemContent(description: description, explanation: explanation))
    }
    
    func defaultSelectedTranslationItem() -> TranslationItem? {
        return nil
    }
}
