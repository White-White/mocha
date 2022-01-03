//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct MachoCellView: View {
    
    let machoComponent: MachoComponent
    let hexDigits: Int
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(machoComponent.primaryName)
                    .lineLimit(1)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .black)
                    .padding(.bottom, 2)
                if let secondaryDescription = machoComponent.secondaryName {
                    Text(secondaryDescription)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .lineLimit(1)
                }
                Text(String(format: "Rnage: 0x%0\(hexDigits)X - 0x%0\(hexDigits)X", machoComponent.fileOffsetInMacho, machoComponent.fileOffsetInMacho + machoComponent.size))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .padding(.top, 2)
                    .lineLimit(1)
                Text(String(format: "Size: 0x%0\(hexDigits)X", machoComponent.size))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .padding(.top, 2)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(isSelected ? Theme.selected : .white)
        }
        .contentShape(Rectangle())
    }
    
    init(_ machoComponent: MachoComponent, isSelected: Bool) {
        self.machoComponent = machoComponent
        self.hexDigits = machoComponent.machoDataSlice.preferredNumberOfHexDigits
        self.isSelected = isSelected
    }
}

struct MachoView: View {
    
    @Binding var macho: Macho
    @State fileprivate var machoComponents: [MachoComponent]
    
    @State fileprivate var selectedMachoComponent: MachoComponent
    @State fileprivate var hexStore: HexLineStore
    
    @State var selectedBinaryRange: Range<Int>?
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(machoComponents, id: \.fileOffsetInMacho) { component in
                        MachoCellView(component, isSelected: selectedMachoComponent == component)
                            .onTapGesture {
                                self.selectedMachoComponent = component
                                self.selectedBinaryRange = component.translationSection(at: 0).terms.first?.range
                                self.hexStore = HexLineStore(component.machoDataSlice)
                                self.hexStore.updateLinesWith(selectedBytesRange: self.selectedBinaryRange)
                            }
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Divider()
            
            VStack(alignment: .leading) {
                MiniMap(machoFileSize: macho.fileSize, selectedMachoComponent: $selectedMachoComponent)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                HStack(alignment: .top, spacing: 0) {
                    HexView(store: $hexStore, selectedBinaryRange: $selectedBinaryRange)
                    TranslationView(machoComponent: $selectedMachoComponent, selectedBinaryRange: $selectedBinaryRange)
                }
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))
            }
        }
        .onChange(of: macho) { newValue in
            self.machoComponents = newValue.machoComponents
            self.selectedMachoComponent = newValue.header
            self.hexStore = HexLineStore(newValue.header.machoDataSlice)
            self.selectedBinaryRange = newValue.header.translationSection(at: 0).terms.first?.range
            self.hexStore.updateLinesWith(selectedBytesRange: self.selectedBinaryRange)
        }
    }
    
    init(_ macho: Binding<Macho>) {
        _macho = macho
        
        // cells
        _machoComponents = State(initialValue: macho.wrappedValue.machoComponents)
        _selectedMachoComponent = State(initialValue: macho.wrappedValue.header)
        let selectedRange = macho.wrappedValue.header.translationSection(at: 0).terms.first?.range
        _selectedBinaryRange = State(initialValue: selectedRange)
        let hexStore = HexLineStore(macho.wrappedValue.header.machoDataSlice)
        hexStore.updateLinesWith(selectedBytesRange: selectedRange)
        _hexStore = State(initialValue: hexStore)
        
    }
}
