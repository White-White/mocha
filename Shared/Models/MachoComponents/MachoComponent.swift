//
//  MachoComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation
import SwiftUI

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
    
    // MARK: Initialization
    
    func runInitializing() { }
    typealias TranslationGroup = [BaseTranslation]
    var translationGroups: [TranslationGroup]!
    func runTranslating() -> [TranslationGroup] { fatalError() }
    
    func fixTranslationDataRange() {
        var currentOffsetInMacho = UInt64(self.offsetInMacho)
        for translationGroup in self.translationGroups {
            for translation in translationGroup {
                translation.dataRangeInMacho = currentOffsetInMacho..<currentOffsetInMacho+translation.bytesCount
                currentOffsetInMacho += translation.bytesCount
            }
        }
    }
    
    private var parentMachoComponents: [MachoComponent] = []
    private var childMachoComponents: [MachoComponent] = []
    
    func addChildComponent(_ childComponent: MachoComponent) {
        guard !self.childMachoComponents.contains(childComponent) else { fatalError() }
        self.childMachoComponents.append(childComponent)
        childComponent.parentMachoComponents.append(self)
    }
    
    final func startAsyncInitialization(readyComponent: MachoComponent? = nil) {
        DispatchQueue.main.async {
            if let readyComponent {
                self.parentMachoComponents.removeAll { $0 == readyComponent }
            }
            if self.parentMachoComponents.isEmpty {
                DispatchQueue.global().async {
                    let tick = TickTock()//.disable()
                    
                    self.runInitializing()
                    tick.tock("Macho Component Init - \(self.title)")
                    self.childMachoComponents.forEach { $0.startAsyncInitialization(readyComponent: self) }
                    self.childMachoComponents.removeAll()
                    
                    self.translationGroups = self.runTranslating()
                    self.fixTranslationDataRange()
                    
                    tick.tock("Generate translation view model - \(self.title)")
                    self.initProgress.finishProgress()
                }
            }
        }
    }
    
    // MARK: Translation Data Source
    
    func numberOfTranslationGroups() -> Int {
        return self.translationGroups.count
    }
    
    func numberOfTranslations(in groupIndex: Int) -> Int {
        return self.translationGroups[groupIndex].count
    }
    
    func translation(at indexPath: IndexPath) -> BaseTranslation {
        return self.translationGroups[indexPath.section][indexPath.item]
    }
    
}

extension MachoComponent {
    var dataRangeInMacho: Range<UInt64> { UInt64(self.offsetInMacho)..<UInt64(self.offsetInMacho + self.dataSize) }
}
