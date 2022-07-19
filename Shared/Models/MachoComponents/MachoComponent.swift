//
//  MachoComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation

class MachoComponent: Equatable, Identifiable, Hashable {
    static func == (lhs: MachoComponent, rhs: MachoComponent) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let title: String
    let data: Data
    var dataSize: Int { data.count }
    var offsetInMacho: Int { data.startIndex }
    
    var initTriggered: Bool = false
    var initDependencies: [MachoComponent?] { [] }
    private var rwLockInitialization = pthread_rwlock_t()
    private var rwLockTranslation = pthread_rwlock_t()
    
    weak var macho: Macho?
    private(set) var translations: [Translation] = []
    
    init(_ data: Data, title: String) {
        self.data = data
        self.title = title
        pthread_rwlock_init(&self.rwLockInitialization, nil)
        pthread_rwlock_init(&self.rwLockTranslation, nil)
    }
    
    func initialize() {
        
    }
    
    func createTranslations() -> [Translation] {
        fatalError() // must override
    }
    
    final func startInitialization(onLocked: @escaping () -> Void) {
        if self.initTriggered { DispatchQueue.global().async { onLocked() }; return }
        DispatchQueue.global().async {
            pthread_rwlock_wrlock(&self.rwLockInitialization)
            onLocked()
            let tick = TickTock()
            self.initialize()
            tick.tock("Macho Component Init - \(self.title)")
            pthread_rwlock_unlock(&self.rwLockInitialization)
        }
        self.initTriggered = true
    }
    
    final func startTranslationInitialization() {
        DispatchQueue.global().async {
            pthread_rwlock_wrlock(&self.rwLockTranslation)
            self.withInitializationDone {
                let tickTranslation = TickTock()
                self.translations = self.createTranslations()
                tickTranslation.tock("Generate \(self.translations.count) translations - \(self.title)")
            }
            pthread_rwlock_unlock(&self.rwLockTranslation)
        }
    }
    
    final func withInitializationDone(_ block: () -> Void) {
        pthread_rwlock_rdlock(&self.rwLockInitialization)
        block()
        pthread_rwlock_unlock(&self.rwLockInitialization)
    }
    
    final func withTranslationInitializationDone(_ block: () -> Void) {
        pthread_rwlock_rdlock(&self.rwLockTranslation)
        block()
        pthread_rwlock_unlock(&self.rwLockTranslation)
    }
    
    final var translationGroupViewModel: TranslationGroupViewModel {
        var viewModel: TranslationGroupViewModel!
        self.withTranslationInitializationDone { viewModel = TranslationGroupViewModel(self) }
        return viewModel
    }
    
}

class MachoUnknownCodeComponent: MachoComponent {
    
    override func createTranslations() -> [Translation] {
        return [Translation(definition: "Unknow", humanReadable: "Mocha doesn's know how to parse this section yet.", bytesCount: .zero, translationType: .rawData)]
    }
    
}

class MachoZeroFilledComponent: MachoComponent {
    
    let runtimeSize: Int
    init(runtimeSize: Int, title: String) {
        self.runtimeSize = runtimeSize
        super.init(Data(), /* dummy data */ title: title)
    }
    
    override func createTranslations() -> [Translation] {
        return [Translation(definition: "Zero Filled Section", humanReadable: "This section has no data in the macho file.\nIts in memory size is \(runtimeSize.hex)", bytesCount: .zero, translationType: .rawData)]
    }
    
}
