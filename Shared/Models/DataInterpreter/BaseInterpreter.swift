//
//  BaseInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

enum InterpreterSettingsKey {
    case shouldDemangleCString
    case stringTableSearchingDelegate
}

protocol Interpreter {
    init(_ data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey: Any]?)
    func numberOfTranslationSections() -> Int
    func translationItems(at section: Int) -> [TranslationItem]
    func sectionTitle(of section: Int) -> String?
}

class BaseInterpreter<Payload>: Interpreter {
    
    let data: DataSlice
    let is64Bit: Bool
    let settings: [InterpreterSettingsKey: Any]?
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
    
    required init(_ data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey : Any]? = nil) {
        self.data = data
        self.is64Bit = is64Bit
        self.settings = settings
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
            self.payloadInside = self.generatePayload()
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

    func translationItems(at section: Int) -> [TranslationItem] {
        fatalError()
    }
    
    func sectionTitle(of section: Int) -> String? {
        return nil
    }
}



class AnonymousInterpreter: BaseInterpreter<AnonymousInterpreter.Dummy> {
    
    struct Dummy {}
    
    var description: String { "Unknown Data" }
    var explanation: String { "Don't know how to interprete these bytes yet." }
    
    override func generatePayload() -> Dummy {
        return Dummy()
    }
    
    override func numberOfTranslationSections() -> Int {
        return 1
    }
    
    override func translationItems(at section: Int) -> [TranslationItem] {
        return [TranslationItem(sourceDataRange: nil,
                                content: TranslationItemContent(description: description, explanation: explanation))]
    }
}

class CodeSignatureInterpreter: AnonymousInterpreter {
    // ref: https://opensource.apple.com/source/Security/Security-55471/sec/Security/Tool/codesign.c
    // we treat parse code signature as a single arbitrary binary
    override var description: String { "Code Signature" }
    override var explanation: String { "We are not parsing this." }
}

class CodeInterpreter: AnonymousInterpreter {
    override var description: String { "Code" }
    override var explanation: String { "This part of the macho file is your machine code. Hopper.app is a better tool for viewing it." }
}
