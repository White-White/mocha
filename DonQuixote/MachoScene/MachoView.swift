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
    @Published var updateElementListViewScrolling = false
    
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
    }
    
    func updateSelectedMachoElement(with machoElement: MachoBaseElement, autoScroll: Bool) {
        self.selectedMachoElement = machoElement
        self.updateElementListViewScrolling = autoScroll
    }
    
    func updateSelectedTranslationGroup(with translationGroup: TranslationGroup) {
        self.hexFiendViewController.updateColorDataRange(with: translationGroup.dataRangeInMacho)
    }
    
    func updateSelectedTranslation(with translation: Translation) {
        self.selectedTranslation = translation
        self.hexFiendViewController.updateSelectedDataRange(with: translation.rangeInMacho, autoScroll: true)
    }
    
    private var isSearching: Bool = false
    func beginSearch(for targetDataIndex: UInt64) async {
        
        if isSearching { return }
        isSearching = true
        
        let inBaseElement = self.allMachoBaseElements.binarySearch { element in
            if element.data.startIndex > targetDataIndex {
                return .searchLeft
            } else if element.data.endIndex <= targetDataIndex {
                return .searchRight
            } else {
                return .matched
            }
        }
        
        let searchResult = await inBaseElement?.searchForTranslation(with: targetDataIndex)
        
        Task { @MainActor in
            if let inBaseElement {
                self.updateSelectedMachoElement(with: inBaseElement, autoScroll: true)
            }
            if let findedGroup = searchResult?.translationGroup {
                self.updateSelectedTranslationGroup(with: findedGroup)
            }
            if let findedTranslation = searchResult?.translation {
                self.updateSelectedTranslation(with: findedTranslation)
            }
        }
        
        isSearching = false
        
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
                                    machoViewState.updateSelectedMachoElement(with: machoElement, autoScroll: false)
                                }
                        }
                    }
                }
                .border(.separator, width: 1)
                .frame(width: ComponentListCell.widthNeeded(for: machoViewState.allMachoBaseElements))
//                .onChange(of: machoViewState.selectedMachoElement) { newValue in
//                    if let newValue,  {
//                        self.scrollControl.autoScrollBaseElementListView = false
//                        withAnimation {
//                            scrollViewProxy.scrollTo(newValue.id)
//                        }
//                    }
//                }
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
                    await machoViewState.beginSearch(for: charIndex)
                }
            }
        }
        .navigationTitle(machoViewState.machoFileName)
    }
    
}
