//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct MachoView: View {
    
    let macho: Macho
    @State var selectedMachoComponentIndex: Int
    @State var translationGroupViewModel: TranslationGroupViewModel
    
    @State var selectedDataRange: Range<UInt64>?
    @State var currentMachoComponentRange: Range<UInt64>
    
    var body: some View {
        HStack(spacing: 4) {
            ComponentListView(macho: macho, selectedMachoComponentIndex: $selectedMachoComponentIndex)
            TranslationGroupView(translationGroupViewModel: translationGroupViewModel, selectedRange: $selectedDataRange)
            HexFiendView(data: macho.machoData, selectedRange: $selectedDataRange, currentMachoComponentRange: $currentMachoComponentRange)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 0))
        .onChange(of: selectedMachoComponentIndex) { newValue in
            self.translationGroupViewModel = macho.allComponents[newValue].translationGroupViewModel
            self.selectedDataRange = self.translationGroupViewModel.dataRangeFirstTranslation
            self.currentMachoComponentRange = self.translationGroupViewModel.dataRangeAllTranslation
        }
    }
    
    init(_ macho: Macho) {
        self.macho = macho
        let initiaSelectedMachoComponentIndex = 0
        _selectedMachoComponentIndex = State(initialValue: initiaSelectedMachoComponentIndex)
        let translationGroupViewModel = macho.allComponents[initiaSelectedMachoComponentIndex].translationGroupViewModel
        _translationGroupViewModel = State(initialValue: translationGroupViewModel)
        _selectedDataRange = State(initialValue: translationGroupViewModel.dataRangeFirstTranslation)
        _currentMachoComponentRange = State(initialValue: translationGroupViewModel.dataRangeAllTranslation)
    }
    
}
