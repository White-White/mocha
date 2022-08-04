//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct MachoView: View {
    
    let macho: Macho
    let machoViewState: MachoViewState
    
    var body: some View {
        HStack(spacing: 4) {
            ComponentListView(machoViewState: machoViewState)
            TranslationsViewContainer(machoViewState: machoViewState)
            HexFiendView(macho: macho, machoViewState: machoViewState)
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
    
    init(_ macho: Macho) {
        self.macho = macho
        self.machoViewState = MachoViewState(macho: macho)
    }
    
}
