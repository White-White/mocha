//
//  MachoComponentView.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/28.
//

import SwiftUI

struct MachoComponentView: View {
    
    let hexDigits: Int
    @Binding var machoComponent: MachoComponent
    
    @State var hexStore: HexadecimalStore
    @State var highlightedDataRange: Range<Int>?
    @State var maxPage: Int
    @State var currentPage: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                HexadecimalView(store: $hexStore, highLightedDataRange: $highlightedDataRange)
                
                VStack {
                    TranslationItemsView(machoComponent: $machoComponent, currentPage: $currentPage, highLightedDataRange: $highlightedDataRange)
                    
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                        Button(action: lastPage) {
                            Label("Last Page", systemImage: "arrow.left")
                        }
                        .disabled(currentPage == 0)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 4))
                        Text("Page: \(currentPage + 1) / \(maxPage + 1)")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 4))
                        Button(action: nextPage) {
                            Label("Next Page", systemImage: "arrow.right")
                        }
                        .disabled(currentPage == maxPage)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 4))
                    }
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
        .onChange(of: machoComponent) { newValue in
            self.hexStore = HexadecimalStore(newValue, hexDigits: hexDigits)
            
            let highLightedDataRange = newValue.firstTransItem?.sourceDataRange
            self.hexStore.updateLinesWith(selectedBytesRange: highLightedDataRange)
            self.highlightedDataRange = highLightedDataRange
            
            self.currentPage = 0
            self.maxPage = newValue.numberOfTranslationSections() / TranslationItemsView.numberOfSectionsInPage
        }
    }
    
    
    init(with machoComponent: Binding<MachoComponent>, hexDigits: Int) {
        self.hexDigits = hexDigits
        
        _machoComponent = machoComponent
        let hexStore = HexadecimalStore(machoComponent.wrappedValue, hexDigits: hexDigits)
        _hexStore = State(initialValue: hexStore)
        
        let highLightedDataRange = machoComponent.wrappedValue.firstTransItem?.sourceDataRange
        hexStore.updateLinesWith(selectedBytesRange: highLightedDataRange)
        _highlightedDataRange = State(initialValue: highLightedDataRange)
        
        _currentPage = State(initialValue: 0)
        _maxPage = State(initialValue: machoComponent.wrappedValue.numberOfTranslationSections() / TranslationItemsView.numberOfSectionsInPage)
    }
    
    func nextPage() {
        currentPage = min(currentPage + 1, machoComponent.numberOfTranslationSections() / TranslationItemsView.numberOfSectionsInPage)
    }
    
    func lastPage() {
        currentPage = max(0, currentPage - 1)
    }
}
