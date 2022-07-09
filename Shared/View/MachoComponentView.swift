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
    @Binding var selectedRange: Range<UInt64>
    @State var translationViewModel: TranslationViewModel
    
    var body: some View {
        VStack {
            TranslationView(selectedRange: $selectedRange, translationViewModel: translationViewModel)
            PageControlView(translationViewModel: translationViewModel)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .onChange(of: machoComponent) { newValue in
            self.translationViewModel = TranslationViewModel(newValue)
        }
    }
    
    init(with machoComponent: Binding<MachoComponent>, hexDigits: Int, selectedRange: Binding<Range<UInt64>>) {
        self.hexDigits = hexDigits
        _machoComponent = machoComponent
        let translationViewModel = TranslationViewModel(machoComponent.wrappedValue)
        _translationViewModel = State(initialValue: translationViewModel)
        _selectedRange = selectedRange
    }
    
}
