//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

@MainActor
class MachoViewState: ObservableObject {
    
    @Published var selectedMachoElement: MachoBaseElement
    @Published var selectedTranslation: Translation?
    
    let macho: Macho
    let machoFileName: String
    let allMachoBaseElements: [MachoBaseElement]
    let hexFiendViewController: HexFiendViewController
    
    init(_ macho: Macho) {
        self.macho = macho
        self.machoFileName = macho.machoFileName
        self.allMachoBaseElements = macho.allElements
        self.selectedMachoElement = macho.machoHeader
        self.hexFiendViewController = HexFiendViewController(data: macho.machoData)
        self.selectFirstTranslationWhenPossible()
    }
    
    func onClick(machoBaseElement: MachoBaseElement) {
        self.selectedMachoElement = machoBaseElement
        self.selectFirstTranslationWhenPossible()
    }
    
    func selectFirstTranslationWhenPossible() {
        Task {
            await self.selectedMachoElement.translationStore.suspendUntilLoaded(callerTag: "Auto select")
            if let firstGroup = self.selectedMachoElement.translationStore.translationGroups.first {
                Task { @MainActor in
                    self.updateHexViewColoredDataRange(with: firstGroup.dataRangeInMacho)
                    self.updateHexViewSelectedDataRange(with: firstGroup.translations.first?.rangeInMacho)
                    self.selectedTranslation = firstGroup.translations.first
                }
            }
        }
    }
    
    func onClick(translation: Translation, in group: TranslationGroup?) {
        self.updateHexViewColoredDataRange(with: group?.dataRangeInMacho)
        self.updateHexViewSelectedDataRange(with: translation.rangeInMacho)
        self.selectedTranslation = translation
    }
    
    private var isSearchingForTranslation: Bool = false
    func onClickHexView(at dataIndexInMacho: UInt64) async {
        
        if isSearchingForTranslation { return }
        isSearchingForTranslation = true
        
        let inBaseElement = self.allMachoBaseElements.binarySearch { element in
            if element.data.startIndex > dataIndexInMacho {
                return .searchLeft
            } else if element.data.endIndex <= dataIndexInMacho {
                return .searchRight
            } else {
                return .matched
            }
        }
        
        let searchResult = await inBaseElement?.searchForTranslation(with: dataIndexInMacho)
        
        Task { @MainActor in
            if let inBaseElement {
                self.selectedMachoElement = inBaseElement
            }
            
            self.updateHexViewColoredDataRange(with: searchResult?.translationGroup?.dataRangeInMacho)
            
            if let findedTranslation = searchResult?.translation {
                self.updateHexViewSelectedDataRange(with: findedTranslation.rangeInMacho)
                self.selectedTranslation = findedTranslation
            }
        }
        
        isSearchingForTranslation = false
        
    }
    
    private func updateHexViewSelectedDataRange(with range: Range<UInt64>?) {
        self.hexFiendViewController.updateSelectedDataRange(with: range, autoScroll: true)
    }
    
    private func updateHexViewColoredDataRange(with range: Range<UInt64>?) {
        self.hexFiendViewController.updateColorDataRange(with: range)
    }
    
}

// generall we shouldn't init States in init method.
// ref: https://swiftcraft.io/blog/how-to-initialize-state-inside-the-views-init-

struct MachoView: View {
    
    @ObservedObject var machoViewState: MachoViewState
    
    var body: some View {
        HStack(spacing: 4) {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(machoViewState.allMachoBaseElements) { machoElement in
                            ComponentListCell(machoElement: machoElement, isSelected: machoElement == machoViewState.selectedMachoElement)
                                .onTapGesture {
                                    self.machoViewState.onClick(machoBaseElement: machoElement)
                                }
                        }
                    }
                }
                .border(.separator, width: 1)
                .frame(width: ComponentListCell.widthNeeded(for: machoViewState.allMachoBaseElements))
                .onChange(of: machoViewState.selectedMachoElement) { newValue in
                    withAnimation {
                        scrollViewProxy.scrollTo(newValue.id)
                    }
                }
            }
            
            TranslationView(machoViewState: self.machoViewState)
            
            ViewControllerRepresentable(viewController: machoViewState.hexFiendViewController)
                .frame(width: machoViewState.hexFiendViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendViewController.bytesPerLine)))
                .border(.separator, width: 1)
                
        }
        .frame(minHeight: 800)
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        
        .onReceive(NotificationCenter.default.publisher(for: HexFiendViewController.MouseDownNoti, object: machoViewState.hexFiendViewController)) { output in
            if let charIndex = output.userInfo?[HexFiendViewController.MouseDownNotiCharIndexKey] as? UInt64 {
                Task {
                    await machoViewState.onClickHexView(at: charIndex)
                }
            }
        }
        .navigationTitle(machoViewState.machoFileName)
    }
    
}
