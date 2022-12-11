//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct MachoView: View {
    
    let macho: Macho
    @State var selectedDataRange: Range<UInt64>?
    @State var selectedMachoComponent: MachoComponent
    @State var hexFiendViewController: HexFiendViewController
    
    var body: some View {
        HStack(spacing: 4) {
            ComponentListView(macho: macho, selectedMachoComponent: $selectedMachoComponent)
            
            TranslationsView(machoComponent: selectedMachoComponent, selectedDataRange: $selectedDataRange)
            
            ViewControllerRepresentable(viewController: self.hexFiendViewController)
                .frame(width: hexFiendViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendViewController.bytesPerLine)))
                .border(.separator, width: 1)
                .onChange(of: selectedDataRange) { newValue in
                    self.hexFiendViewController.selectedDataRange = newValue
                }
                .onChange(of: selectedMachoComponent) { newValue in
                    self.hexFiendViewController.selectedComponentDataRange = newValue.dataRangeInMacho
                }
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
    
    init(_ macho: Macho) {
        // generall we shouldn't init States in init method.
        // ref: https://swiftcraft.io/blog/how-to-initialize-state-inside-the-views-init-
        // but MachoView is not refreshed once created, so it's acceptable here
        
        _selectedDataRange = State(initialValue: nil)
        _selectedMachoComponent = State(initialValue: macho.machoHeader)
        
        let hexFiendViewController = HexFiendViewController(data: macho.machoData)
        hexFiendViewController.selectedComponentDataRange = macho.machoHeader.dataRangeInMacho
        _hexFiendViewController = State(initialValue: hexFiendViewController)
        
        self.macho = macho
    }
    
}
