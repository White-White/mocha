//
//  MachoComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation

class MachoComponent: Equatable, Identifiable {
    
    static func == (lhs: MachoComponent, rhs: MachoComponent) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    
    let data: Data
    var dataSize: Int { data.count }
    var offsetInMacho: Int { data.startIndex }
    
    let title: String
    let subTitle: String
    
    private var rwLock = pthread_rwlock_t()
    
    init(_ data: Data, title: String, subTitle: String) {
        self.data = data
        self.title = title
        self.subTitle = subTitle
        pthread_rwlock_init(&self.rwLock, nil)
    }
    
    weak var macho: Macho?
    
    private var initialized: Bool = false
    func initialize() {
        
    }
    
    private(set) var translations: [Translation] = []
    func createTranslations() -> [Translation] {
        fatalError()
    }
    
    final func startInitialization(async: Bool = true) {
        let initBlock = {
            pthread_rwlock_wrlock(&self.rwLock)
            if self.initialized { pthread_rwlock_unlock(&self.rwLock); return }
            let tick = TickTock()
            self.initialize()
            tick.tock("Macho Component Async Init - \(self.title),\(self.subTitle)")
            self.translations = self.createTranslations()
            tick.tock("Generate \(self.translations.count) translations - \(self.title),\(self.subTitle)")
            self.initialized = true
            pthread_rwlock_unlock(&self.rwLock)
        }
        if async {
            DispatchQueue.global().async { initBlock() }
        } else {
            initBlock()
        }
    }
    
    final func withInitializationDone(_ block: () -> Void) {
        self.startInitialization(async: false)
        pthread_rwlock_rdlock(&self.rwLock)
        block()
        pthread_rwlock_unlock(&self.rwLock)
    }
    
    final var translationGroup: TranslationGroup {
        var translations: [Translation] = []
        self.withInitializationDone { translations = self.translations }
        return TranslationGroup(translations, startOffsetInMacho: self.offsetInMacho)
    }
    
}

class MachoUnknownCodeComponent: MachoComponent {
    
    override func createTranslations() -> [Translation] {
        return [Translation(description: "Unknow", explanation: "Mocha doesn's know how to parse this section yet.", bytesCount: .zero)]
    }
    
}

class MachoZeroFilledComponent: MachoComponent {
    
    let runtimeSize: Int
    //TODO: zero fill component out of order
    init(runtimeSize: Int, title: String, subTitle: String) {
        self.runtimeSize = runtimeSize
        super.init(Data(), /* dummy data */ title: title, subTitle: subTitle)
    }
    
    override func createTranslations() -> [Translation] {
        return [Translation(description: "Zero Filled Section", explanation: "This section has no data in the macho file.\nIts in memory size is \(runtimeSize.hex)", bytesCount: .zero,
                            explanationStyle: ExplanationStyle.extraDetail)]
    }
    
}
