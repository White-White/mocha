//
//  ComponentListView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/17.
//

import SwiftUI

struct ComponentListCell: View {
    
    @Binding var selectedMachoComponent: MachoComponent
    @Binding var alertPresented: Bool
    
    let machoComponent: MachoComponent
    let isSelected: Bool
    var title: String { machoComponent.title }
    var offsetInMacho: Int { machoComponent.offsetInMacho }
    var dataSize: Int { machoComponent.dataSize }
    
    @ObservedObject var initProgress: InitProgress
    @State var isDone: Bool
    @State var progress: Float
    
    var body: some View {
        ZStack(alignment: .leading) {
            if !isDone {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { reader in
                        Spacer()
                            .frame(width: reader.size.width * CGFloat(progress))
                            .background(.gray)
                            .animation(.default, value: progress)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 12).bold())
                        .padding(.bottom, 2)
                    
                    if let subTitle = machoComponent.subTitle {
                        Text(subTitle)
                            .font(.system(size: 10).bold())
                            .padding(.bottom, 2)
                    }
                    
                    Text(String(format: "Range: 0x%0X - 0x%0X", offsetInMacho, offsetInMacho + dataSize))
                        .font(.system(size: 11))
                    
                    Text(String(format: "Size: 0x%0X(%d) Bytes", dataSize, dataSize))
                        .font(.system(size: 11))
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                Divider()
            }
            .background(isDone ? (isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white) : .white.opacity(0.5))
        }
        .onTapGesture {
            guard isDone else { alertPresented = true; return }
            guard !isSelected else { return }
            self.selectedMachoComponent = self.machoComponent
        }
        .onChange(of: initProgress.isDone) { newValue in
            self.isDone = newValue
        }
        .onChange(of: initProgress.progress) { newValue in
            self.progress = newValue
        }
        .onChange(of: machoComponent) { newValue in
            self.isDone = newValue.initProgress.isDone
            self.progress = newValue.initProgress.progress
        }
    }
    
    init(machoComponent: MachoComponent, selectedMachoComponent: Binding<MachoComponent>, alertPresented: Binding<Bool>) {
        _alertPresented = alertPresented
        _selectedMachoComponent = selectedMachoComponent
        self.isDone = machoComponent.initProgress.isDone
        self.progress = machoComponent.initProgress.progress
        self.machoComponent = machoComponent
        self.isSelected = (machoComponent == selectedMachoComponent.wrappedValue)
        self.initProgress = machoComponent.initProgress
    }
    
}

struct ComponentListView: View {
    
    let macho: Macho
    @Binding var selectedMachoComponent: MachoComponent
    @State var alertPresented: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(macho.allComponents) { machoComponent in
                    ComponentListCell(machoComponent: machoComponent, selectedMachoComponent: $selectedMachoComponent, alertPresented: $alertPresented)
                }
            }
        }
        .border(.separator, width: 1)
        .frame(width: self.widthNeede(for: macho))
        .alert("Component is loading", isPresented: $alertPresented) {
            
        }
    }
    
    func widthNeede(for macho: Macho) -> CGFloat {
        return macho.allComponents.reduce(0) { partialResult, component in
            let attriString = NSAttributedString(string: component.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        } + 16
    }
  
    init(macho: Macho, selectedMachoComponent: Binding<MachoComponent>) {
        self.macho = macho
        _selectedMachoComponent = selectedMachoComponent
    }
    
}
