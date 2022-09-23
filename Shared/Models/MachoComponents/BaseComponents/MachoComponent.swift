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
        
    }
    
    func asyncTranslate() {
        fatalError()
    }
    
    private var hasStartedInit: Bool = false
    private var dependentComponents: [MachoComponent] = []
    private var dependencyComponents: [MachoComponent]  = []
    
    final func addDependency(_ dependency: MachoComponent) {
        guard Thread.isMainThread else { fatalError() }
        dependency.dependentComponents.append(self)
        self.dependencyComponents.append(dependency)
    }
    
    final func startAsyncInitialization() {
        guard Thread.isMainThread && !self.hasStartedInit else { fatalError() }
        guard self.dependencyComponents.isEmpty else { return }
        self.hasStartedInit = true
        DispatchQueue.global().async {
            let tick = TickTock().disable()
            self.asyncInitialize()
            tick.tock("Macho Component Init - \(self.title)")
            self.dependentComponents.forEach { $0.didInitialize(dependencyComponent: self) }
            self.asyncTranslate()
            tick.tock("Generate translation view model - \(self.title)")
            self.initProgress.finishProgress()
        }
    }
    
    private final func didInitialize(dependencyComponent: MachoComponent) {
        DispatchQueue.main.async {
            guard let dependentIndex = dependencyComponent.dependentComponents.firstIndex(of: self) else { fatalError() }
            dependencyComponent.dependentComponents.remove(at: dependentIndex)
            guard let dependencyIndex = self.dependencyComponents.firstIndex(of: dependencyComponent) else { fatalError() }
            self.dependencyComponents.remove(at: dependencyIndex)
            self.startAsyncInitialization()
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
