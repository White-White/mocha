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
    
    weak var macho: Macho?
    let initProgress = InitProgress()
    
    init(_ data: Data, title: String, subTitle: String? = nil) {
        self.data = data
        self.title = title
        self.subTitle = subTitle
    }
    
    func asyncInitialize() {
        // function stub. subclass should override and exec init code
    }
    
    func asyncTranslate() {
        // function stub. subclass should override and exec tranlation code
    }
    
    var childComponents: [MachoComponent] = []
    var parentComponent: MachoComponent? {
        willSet { guard parentComponent == nil else { fatalError() } }
        didSet { parentComponent!.childComponents.append(self) }
    }
    var hasParentComponent: Bool { parentComponent != nil }
    
    final func startAsyncInitialization() {
        DispatchQueue.global().async {
            let tick = TickTock().disable()
            self.asyncInitialize()
            tick.tock("Macho Component Init - \(self.title)")
            DispatchQueue.main.async {
                self.childComponents.forEach { $0.startAsyncInitialization() }
            }
            self.asyncTranslate()
            tick.tock("Generate translation view model - \(self.title)")
            self.initProgress.finishProgress()
        }
    }
    
}

class ModeledTranslationComponent: MachoComponent {
    
    private(set) var modeledTranslationsViewModel: ModeledTranslationsViewModel!

    override func asyncTranslate() {
        self.modeledTranslationsViewModel = ModeledTranslationsViewModel(translationSections: self.createTranslationSections(), machoComponentStartOffset: self.offsetInMacho)
    }
    
    func createTranslationSections() -> [TranslationSection] {
        fatalError()
    }
    
}
