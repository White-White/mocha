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
    @State var selectedMachoElement: MachoBaseElement
    @State var hexFiendViewController: HexFiendViewController?
    
    var body: some View {
        HStack(spacing: 4) {
            
            ComponentListView(macho: macho, selectedMachoElement: $selectedMachoElement)
            
            TranslationsView(machoBaseElement: selectedMachoElement, selectedDataRange: $selectedDataRange)
            
            if let hexFiendViewController {
                ViewControllerRepresentable(viewController: hexFiendViewController)
                    .frame(width: hexFiendViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendViewController.bytesPerLine)))
                    .border(.separator, width: 1)
                //                .onChange(of: selectedDataRange) { newValue in
                //                    self.hexFiendViewController.selectedDataRange = newValue
                //                }
                //                .onChange(of: selectedMachoElement) { newValue in
                //                    self.hexFiendViewController.selectedComponentDataRange = newValue.dataRangeInMacho
                //                }
            }
            
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .onChange(of: self.macho) { newValue in
            let hexFiendViewController = HexFiendViewController(data: macho.machoData)
            hexFiendViewController.selectedComponentDataRange = macho.machoHeader.dataRangeInMacho
            self.hexFiendViewController = hexFiendViewController
        }
    }
    
    init(_ fileURL: URL?) {
        guard let fileURL else { fatalError() }
        
        // generall we shouldn't init States in init method.
        // ref: https://swiftcraft.io/blog/how-to-initialize-state-inside-the-views-init-
        // but MachoView is not refreshed once created, so it's acceptable here
        
        let fileData = try! Data(contentsOf: fileURL)
        let unixBinary = try! MachoMetaData(fileName: fileURL.lastPathComponent, machoData: fileData)
        let macho = unixBinary.macho
        self.macho = macho
        
        _selectedDataRange = State(initialValue: nil)
        _selectedMachoElement = State(initialValue: macho.machoHeader)
        _hexFiendViewController = State(initialValue: nil)
        
    }
    
}
