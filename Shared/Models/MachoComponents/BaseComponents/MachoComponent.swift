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
    let subTitle: String?
    let data: Data
    var dataSize: Int { data.count }
    var offsetInMacho: Int { data.startIndex }
    
    var initTriggered: Bool = false
    var translationInitTriggered: Bool = false
    
    private var rwLockInitialization = pthread_rwlock_t()
    private var rwLockTranslation = pthread_rwlock_t()
    
    weak var macho: Macho?
    let initProgress = InitProgress()
    
    init(_ data: Data, title: String, subTitle: String? = nil) {
        self.data = data
        self.title = title
        self.subTitle = subTitle
        pthread_rwlock_init(&self.rwLockInitialization, nil)
        pthread_rwlock_init(&self.rwLockTranslation, nil)
    }
    
    var hasMonsterSizedTranslations: Bool { false }
    
    func asyncInitialize() {
        
    }
    
    func asyncInitializeTranslations() {
        fatalError()
    }
    
    var initDependencies: [MachoComponent?] { [] }
    var translationInitDependencies: [MachoComponent?] { [] }
}

extension MachoComponent {
    
    final func startAsyncInitialization(onLocked: @escaping () -> Void) {
        DispatchQueue.global().async {
            pthread_rwlock_wrlock(&self.rwLockInitialization)
            onLocked()
            let tick = TickTock()
            self.asyncInitialize()
            tick.tock("Macho Component Init - \(self.title)")
            pthread_rwlock_unlock(&self.rwLockInitialization)
        }
    }
    
    final func withInitializationDone(_ block: () -> Void) {
        pthread_rwlock_rdlock(&self.rwLockInitialization)
        block()
        pthread_rwlock_unlock(&self.rwLockInitialization)
    }
    
}

extension MachoComponent {
    
    final func startAsyncInitializeTranslation(onLocked: @escaping () -> Void) {
        DispatchQueue.global().async {
            pthread_rwlock_wrlock(&self.rwLockTranslation)
            onLocked()
            self.withInitializationDone {
                let tickTranslation = TickTock()
                self.asyncInitializeTranslations()
                tickTranslation.tock("Generate translation view model - \(self.title)")
            }
            pthread_rwlock_unlock(&self.rwLockTranslation)
        }
    }
    
    final func withTranslationInitializationDone<T>(_ block: () -> T) -> T {
        let ret: T
        pthread_rwlock_rdlock(&self.rwLockTranslation)
        ret = block()
        pthread_rwlock_unlock(&self.rwLockTranslation)
        return ret
    }
    
}

class ModeledTranslationComponent: MachoComponent {
    
    private(set) var modeledTranslationsViewModel: ModeledTranslationsViewModel!

    override func asyncInitializeTranslations() {
        self.modeledTranslationsViewModel = ModeledTranslationsViewModel(translationSections: self.createTranslationSections(), machoComponentStartOffset: self.offsetInMacho)
    }
    
    func createTranslationSections() -> [TranslationSection] {
        fatalError()
    }
    
}
