//
//  MachoLazyComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/28.
//

import Foundation

class MachoLazyComponent<Payload>: MachoComponent {
    
    let is64Bit: Bool
    var macho: Macho { machoInside! }
    private weak var machoInside: Macho?
    var shouldPreload: Bool { false }
    
    private let preloadingLock = NSRecursiveLock()
    private let preloadingQueue: DispatchQueue = DispatchQueue.global()
    private var hasPreloaded = false
    private var payloadInside: Payload?
    
    override var componentTitle: String { title }
    override var componentSubTitle: String? { subTitle }
    
    private let title: String
    private let subTitle: String?
    
    init(_ data: Data, macho: Macho, is64Bit: Bool, title: String, subTitle: String?) {
        self.title = title
        self.subTitle = subTitle
        self.is64Bit = is64Bit
        self.machoInside = macho
        super.init(data)
        self.preloadIfNeeded()
    }
    
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
        fatalError()
    }
}
