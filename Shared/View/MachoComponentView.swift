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
    @State var hexadecimalViewModel: HexadecimalViewModel
    @State var translationViewModel: TranslationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                HexadecimalView(viewModel: hexadecimalViewModel)
                TranslationView(translationViewModel: translationViewModel)
            }
            PageControlView(translationViewModel: translationViewModel)
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .onChange(of: machoComponent) { newValue in
            self.translationViewModel = TranslationViewModel(newValue)
            self.hexadecimalViewModel = HexadecimalViewModel(newValue, translationViewModel: self.translationViewModel, hexDigits: hexDigits)
        }
    }
    
    init(with machoComponent: Binding<MachoComponent>, hexDigits: Int) {
        self.hexDigits = hexDigits
        _machoComponent = machoComponent
        let translationViewModel = TranslationViewModel(machoComponent.wrappedValue)
        _translationViewModel = State(initialValue: translationViewModel)
        _hexadecimalViewModel = State(initialValue: HexadecimalViewModel(machoComponent.wrappedValue,
                                                                         translationViewModel: translationViewModel,
                                                                         hexDigits: hexDigits))
    }
    
}
