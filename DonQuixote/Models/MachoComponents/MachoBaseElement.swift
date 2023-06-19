//
//  MachoBaseElement.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation
import SwiftUI

actor TranslationStore: ObservableObject {
    
    @MainActor @Published var translationGroups: [TranslationGroup] = []
    
    let tag: String
    init(tag: String) {
        self.tag = tag
    }
    
    @MainActor @Published var loadingProgress: Float?
    @MainActor private(set) var loaded: Bool = false
    private var isLoading: Bool = false
    
    @MainActor
    func update(loadingProgress: Float) {
        self.loadingProgress = loadingProgress
    }
    
    func loadTranslations(from machoBaseElement: MachoBaseElement) async {
        if self.isLoading { return }
        self.isLoading = true
        let tick = TickTock()
        await machoBaseElement.loadTranslations()
        machoBaseElement.updateRangeForTranslations()
        tick.tock("\(tag) translation")
        Task { @MainActor in // dispatch sync to main thread
            self.translationGroups = machoBaseElement.translationGroupCache
            self.loaded = true
        }
    }
    
    func suspendUntilLoaded(callerTag: String, progressMonitor: (@MainActor @Sendable (Float?) -> Void)? = nil) async {
        var showLog: Bool = false
        while await !(self.loaded) {
            showLog = true
            Log.warning("\(callerTag) now suppends due to \(self.tag) is loading translations ⏳")
            await progressMonitor?(self.loadingProgress)
            do {
                try Task.checkCancellation()
            } catch {
                Log.warning("\(callerTag) quited waiting \(self.tag) to loading translations")
                return
            }
            await Task.yield()
        }
        if showLog {
            Log.warning("\(callerTag) now continues since \(self.tag) is done loading translations ✅")
        }
    }
    
}

actor AsyncInitProtection {
   
    private var initing: Bool = false
    var inited: Bool = false
    
    let tag: String
    init(tag: String) {
        self.tag = tag
    }
    
    func beginInitIfNeeded(for machoBaseElement: MachoBaseElement) async {
        if self.initing { return }
        let tick = TickTock()
        self.initing = true
        await machoBaseElement.asyncInit()
        self.inited = true
        tick.tock("macho element \(tag) done init.")
    }
    
    func suspendUntilInited() async {
        while !(self.inited) {
            await Task.yield()
        }
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
    
    let translationStore: TranslationStore
    let asyncInitProtector: AsyncInitProtection
    
    init(_ data: Data, title: String, subTitle: String?) {
        self.data = data
        self.title = title
        self.subTitle = subTitle
        let tag = "\(title) \(subTitle ?? "")"
        self.translationStore = TranslationStore(tag: tag)
        self.asyncInitProtector = AsyncInitProtection(tag: tag)
        self.asyncLoadTranslations()
    }
    
    func asyncInit() async {
        
    }
    
    func loadTranslations() async {
        fatalError()
    }
    
    fileprivate var translationGroupCache: [TranslationGroup] = []
    final func save(translations: [Translation]) async {
        self.translationGroupCache.append(TranslationGroup(translations: translations))
    }
    
    func updateRangeForTranslations() {
        var rangeBase = self.data.startIndex
        var updatedTranslationGroups: [TranslationGroup] = []
        for translationGroup in self.translationGroupCache {
            var updatedTranslations: [Translation] = []
            for var translation in translationGroup.translations {
                translation.updateRange(with: UInt64(rangeBase)..<UInt64((rangeBase + translation.bytesCount)))
                rangeBase += translation.bytesCount
                updatedTranslations.append(translation)
            }
            updatedTranslationGroups.append(TranslationGroup(translations: updatedTranslations))
        }
        self.translationGroupCache = updatedTranslationGroups
    }
    
    private func asyncLoadTranslations() {
        Task {
            await self.asyncInitProtector.beginInitIfNeeded(for: self)
            await self.translationStore.loadTranslations(from: self)
        }
    }
    
    struct TranslationSearchResult {
        let translationGroup: TranslationGroup?
        let translation: Translation?
    }
    
    func searchForTranslation(with targetDataIndex: UInt64) async -> TranslationSearchResult? {
        
        await self.translationStore.suspendUntilLoaded(callerTag: "Translation search")
        
        let findedGroup = await self.translationStore.translationGroups.binarySearch { group in
            guard let startIndex = group.translations.first?.rangeInMacho?.startIndex,
                  let endIndex = group.translations.last?.rangeInMacho?.endIndex else  {
                fatalError()
            }
            if startIndex > targetDataIndex {
                return .searchLeft
            } else if endIndex <= targetDataIndex {
                return .searchRight
            } else {
                return .matched
            }
        }
        
        let findedTranslation = findedGroup?.translations.binarySearch(matchCheck: { translation in
            guard let startIndex = translation.rangeInMacho?.startIndex,
                  let endIndex = translation.rangeInMacho?.endIndex else  {
                fatalError()
            }
            if startIndex > targetDataIndex {
                return .searchLeft
            } else if endIndex <= targetDataIndex {
                return .searchRight
            } else {
                return .matched
            }
        })
        
        return TranslationSearchResult(translationGroup: findedGroup, translation: findedTranslation)
        
    }
    
}
