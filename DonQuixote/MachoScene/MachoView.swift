//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

// generall we shouldn't init States in init method.
// ref: https://swiftcraft.io/blog/how-to-initialize-state-inside-the-views-init-

struct MachoView: View {
    
    let macho: Macho
    let hexFiendViewController: HexFiendViewController
    
    @State var selectedTranslation: Translation?
    @State var selectedMachoElement: MachoBaseElement?
    
    @State var autoScrollBaseElementListView: Bool = false
    @State var autoScrollTranslationView: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(macho.allElements) { machoElement in
                            ComponentListCell(machoElement: machoElement, isSelected: machoElement == selectedMachoElement)
                                .onTapGesture {
                                    self.selectedMachoElement = nil
                                    
                                    Task { @MainActor in
                                        self.autoScrollBaseElementListView = false
                                        self.autoScrollTranslationView = true
                                        self.selectedMachoElement = machoElement
                                        if let translationGroup = machoElement.translationStore.translationGroups.first {
                                            if let translationGroupDataRangeStart = translationGroup.first?.rangeInMacho?.startIndex,
                                               let translationGroupDataRangeEnd = translationGroup.last?.rangeInMacho?.endIndex {
                                                self.hexFiendViewController.updateColorDataRange(with: translationGroupDataRangeStart..<translationGroupDataRangeEnd)
                                            }
                                            self.selectedTranslation = translationGroup.first
                                            self.hexFiendViewController.updateSelectedDataRange(with: self.selectedTranslation?.rangeInMacho, autoScroll: true)
                                        }
                                    }
                                }
                        }
                    }
                }
                .border(.separator, width: 1)
                .frame(width: ComponentListCell.widthNeeded(for: macho.allElements))
                .onChange(of: selectedMachoElement) { newValue in
                    if let newValue, self.autoScrollBaseElementListView {
                        self.autoScrollBaseElementListView = false
                        withAnimation {
                            scrollViewProxy.scrollTo(newValue.id)
                        }
                    }
                }
            }
            
            VStack {
                if let selectedMachoElement {
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(0..<selectedMachoElement.translationStore.translationGroups.count, id: \.self) { groupIndex in
                                    ForEach(selectedMachoElement.translationStore.translationGroups[groupIndex]) { translation in
                                        SingleTranslationView(translation: translation, isSelected: selectedTranslation == translation)
                                            .onTapGesture {
                                                let translationGroup = selectedMachoElement.translationStore.translationGroups[groupIndex]
                                                if let translationGroupDataRangeStart = translationGroup.first?.rangeInMacho?.startIndex,
                                                   let translationGroupDataRangeEnd = translationGroup.last?.rangeInMacho?.endIndex {
                                                    self.hexFiendViewController.updateColorDataRange(with: translationGroupDataRangeStart..<translationGroupDataRangeEnd)
                                                }
                                                self.selectedTranslation = translation
                                                self.hexFiendViewController.updateSelectedDataRange(with: translation.rangeInMacho, autoScroll: true)
                                            }
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedTranslation) { newValue in
                            if let newValue, self.autoScrollTranslationView {
                                self.autoScrollTranslationView = false
                                withAnimation {
                                    scrollViewProxy.scrollTo(newValue.id)
                                }
                            }
                        }
                    }
                } else {
                    VStack { }
                }
            }
            .frame(minWidth: 500)
            
            ViewControllerRepresentable(viewController: self.hexFiendViewController)
                .frame(width: hexFiendViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendViewController.bytesPerLine)))
                .border(.separator, width: 1)
                
        }
        .frame(minHeight: 800)
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        
        .onReceive(NotificationCenter.default.publisher(for: HexFiendViewController.MouseDownNoti, object: self.hexFiendViewController)) { output in
            if let charIndex = output.userInfo?[HexFiendViewController.MouseDownNotiCharIndexKey] as? UInt64 {
                if let finded = self.macho.findTranslation(near: charIndex) {
                    
                    let findedTranslation = finded.0
                    let findedTranslationGroup = finded.1
                    let inMachoElement = finded.2
                    
                    self.autoScrollBaseElementListView = true
                    self.autoScrollTranslationView = true
                    
                    self.selectedMachoElement = inMachoElement
                    self.selectedTranslation = findedTranslation
                    
                    if let translationGroupDataRangeStart = findedTranslationGroup.first?.rangeInMacho?.startIndex,
                       let translationGroupDataRangeEnd = findedTranslationGroup.last?.rangeInMacho?.endIndex {
                        self.hexFiendViewController.updateColorDataRange(with: translationGroupDataRangeStart..<translationGroupDataRangeEnd)
                    }
                    self.hexFiendViewController.updateSelectedDataRange(with: findedTranslation.rangeInMacho, autoScroll: false)
                }
            }
        }
        .navigationTitle(macho.machoFileName)
    }
    
}

extension Macho {
    
    @MainActor
    func findTranslation(near targetIndex: UInt64) -> (Translation, TranslationGroup, MachoBaseElement)? {
        
        let inBaseElement = self.beginCustomSearch(in: self.allElements) { baseElement in
            if baseElement.data.startIndex > targetIndex {
                return .searchLeft
            } else if baseElement.data.endIndex <= targetIndex {
                return .searchRight
            } else {
                return .matched
            }
        }
        
        let findedTranslationGroup =  self.beginCustomSearch(in: inBaseElement?.translationStore.translationGroups) { group in
            guard let startIndex = group.first?.rangeInMacho?.startIndex,
                  let endIndex = group.last?.rangeInMacho?.endIndex else  {
                fatalError()
            }
            if startIndex > targetIndex {
                return .searchLeft
            } else if endIndex <= targetIndex {
                return .searchRight
            } else {
                return .matched
            }
        }
        
        let findedTranslation = self.beginCustomSearch(in: findedTranslationGroup) { translation in
            guard let startIndex = translation.rangeInMacho?.startIndex,
                  let endIndex = translation.rangeInMacho?.endIndex else  {
                fatalError()
            }
            if startIndex > targetIndex {
                return .searchLeft
            } else if endIndex <= targetIndex {
                return .searchRight
            } else {
                return .matched
            }
        }
        
        if let findedTranslation, let findedTranslationGroup, let inBaseElement {
            return (findedTranslation, findedTranslationGroup, inBaseElement)
        } else {
            return nil
        }
    }
    
    private enum CustomSearchMatchResult {
        case searchLeft
        case matched
        case searchRight
    }
    
    private func beginCustomSearch<T>(in array: Array<T>?, matchCheck: (_ element: T) -> CustomSearchMatchResult) -> T? {
        guard let array = array else { return nil }
        return customSearch(in: array, lower: 0, upper: array.count - 1, matchCheck: matchCheck)
    }
    
    private func customSearch<T>(in array: Array<T>, lower: Int, upper: Int, matchCheck: (_ element: T) -> CustomSearchMatchResult) -> T? {
        // false, search left
        // true search right
        guard lower <= upper else { return nil }
        let mid = lower + (upper - lower) / 2
        let element = array[mid]
        switch matchCheck(array[mid]) {
        case .searchLeft:
            return customSearch(in: array, lower: lower, upper: mid - 1, matchCheck: matchCheck)
        case .searchRight:
            return customSearch(in: array, lower: mid + 1, upper: upper, matchCheck: matchCheck)
        case .matched:
            return element
        }
    }
    
}
