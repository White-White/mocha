//
//  MachoBaseElement.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation
import SwiftUI

typealias TranslationGroup = [Translation]

actor TranslationStore: ObservableObject {
    
    @MainActor @Published var translationGroups: [TranslationGroup] = []
    
    func loadTranslations(from machoBaseElement: MachoBaseElement) async {
        await machoBaseElement.loadTranslations()
        machoBaseElement.updateRangeForTranslations()
        Task { @MainActor in
            self.translationGroups = machoBaseElement.translationGroupCache
        }
    }
    
}

private actor MachoBaseElementStatus {
    
    private var initing: Bool = false
    var inited: Bool = false
    
    func beginInitIfNeeded(for machoBaseElement: MachoBaseElement) async {
        if self.initing { return }
        self.initing = true
        await machoBaseElement.asyncInit()
        self.inited = true
    }
    
}

class MachoBaseElement: @unchecked Sendable, Equatable, Identifiable {
    
    static func == (lhs: MachoBaseElement, rhs: MachoBaseElement) -> Bool {
        return lhs === rhs
    }
    
    let title: String
    let subTitle: String?
    let data: Data
    var dataSize: Int { data.count }
    var offsetInMacho: Int { data.startIndex }
    
    let translationStore = TranslationStore()
    private let initStatus = MachoBaseElementStatus()
    
    let initProgress = InitProgress()
    
    init(_ data: Data, title: String, subTitle: String?) {
        self.data = data
        self.title = title
        self.subTitle = subTitle
        self.asyncLoadTranslations()
    }
    
    func asyncInit() async {
        
    }
    
    func waitUntilInitDone() async {
        while !(await self.initStatus.inited) {
            await Task.yield()
        }
    }
    
    func loadTranslations() async {
        fatalError()
    }
    
    fileprivate var translationGroupCache: [TranslationGroup] = []
    final func save(translationGroup: TranslationGroup) async {
        self.translationGroupCache.append(translationGroup)
    }
    
    func updateRangeForTranslations() {
        var rangeBase = self.data.startIndex
        var updatedTranslationGroups: [TranslationGroup] = []
        for translationGroup in self.translationGroupCache {
            var updatedTranslationGroup: TranslationGroup = []
            for var translation in translationGroup {
                translation.updateRange(with: UInt64(rangeBase)..<UInt64((rangeBase + translation.bytesCount)))
                rangeBase += translation.bytesCount
                updatedTranslationGroup.append(translation)
            }
            updatedTranslationGroups.append(updatedTranslationGroup)
        }
        self.translationGroupCache = updatedTranslationGroups
    }
    
    private func asyncLoadTranslations() {
        Task {
            await self.initStatus.beginInitIfNeeded(for: self)
            await self.translationStore.loadTranslations(from: self)
        }
    }
    
}
