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
    
    var body: some View {
        HStack(spacing: 4) {
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(macho.allElements) { machoElement in
                            ComponentListCell(machoElement: machoElement, isSelected: machoElement == selectedMachoElement)
                                .onTapGesture {
                                    if self.selectedMachoElement == machoElement { return }
                                    self.selectedMachoElement = machoElement
                                    self.selectedTranslation = machoElement.translationStore.translationGroups.first?.first
                                }
                        }
                    }
                }
                .border(.separator, width: 1)
                .frame(width: ComponentListCell.widthNeeded(for: macho.allElements))
                .onChange(of: selectedMachoElement) { newValue in
                    if let newValue {
                        withAnimation {
                            scrollViewProxy.scrollTo(newValue.id, anchor: .center)
                        }
                    }
                }
            }
            
            if let selectedMachoElement {
                TranslationsView(selectedTranslation: $selectedTranslation, translationContainer: selectedMachoElement.translationStore)
            } else {
                VStack {
                    
                }
                .frame(minWidth: 500)
            }
            
            ViewControllerRepresentable(viewController: self.hexFiendViewController)
                .frame(width: hexFiendViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendViewController.bytesPerLine)))
                .border(.separator, width: 1)
                
        }
        .frame(minHeight: 800)
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .onChange(of: selectedMachoElement) { newValue in
            if let newValue {
                self.hexFiendViewController.selectedComponentDataRange = newValue.dataRangeInMacho
            }
        }
        .onChange(of: selectedTranslation) { translation in
            self.updateHexViewSelectionRange(with: translation)
        }
        .onReceive(NotificationCenter.default.publisher(for: HexFiendViewController.MouseDownNoti, object: self.hexFiendViewController)) { output in
            if let charIndex = output.userInfo?[HexFiendViewController.MouseDownNotiCharIndexKey] as? UInt64 {
                if let finded = self.macho.findTranslation(near: charIndex) {
                    let inMachoElement = finded.1
                    let findedTranslation = finded.0
                    self.selectedMachoElement = inMachoElement
                    self.selectedTranslation = findedTranslation
                    self.updateHexViewSelectionRange(with: findedTranslation)
                }
            }
        }
    }
    
    @MainActor
    func updateHexViewSelectionRange(with translation: Translation?) {
        if let translationDataRange = translation?.rangeInMacho {
            self.hexFiendViewController.selectedDataRange = UInt64(translationDataRange.lowerBound)..<UInt64(translationDataRange.upperBound)
        }
    }
    
}

extension Macho {
    
    @MainActor
    func findTranslation(near targetIndex: UInt64) -> (Translation, MachoBaseElement)? {
        var findedTranslation: Translation?
        var inBaseElement: MachoBaseElement?
        self.allElements.reversed().forEach { baseElement in
            if baseElement.data.startIndex > targetIndex || baseElement.data.endIndex < targetIndex {
                return
            }
            for translationGroup in baseElement.translationStore.translationGroups {
                if let firstTranslationRange = translationGroup.first?.rangeInMacho, let lastTranslationRange = translationGroup.last?.rangeInMacho {
                    if firstTranslationRange.startIndex > targetIndex || lastTranslationRange.endIndex < targetIndex {
                        continue
                    }
                }
                for translation in translationGroup {
                    if let translationRange = translation.rangeInMacho, (translationRange.startIndex <= targetIndex && translationRange.endIndex >= targetIndex) {
                        inBaseElement = baseElement
                        findedTranslation = translation
                        return
                    }
                }
            }
        }
        if let findedTranslation, let inBaseElement {
            return (findedTranslation, inBaseElement)
        } else {
            return nil
        }
    }
    
}
