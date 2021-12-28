//
//  FileView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct FileViewCell: View {
    
    let fileName: String
    let arch: String
    let fileSize: Int
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(fileName)
                    .lineLimit(1)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .black)
                Text("Arch: \(arch)")
                    .lineLimit(1)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(FileSize(fileSize).string)
                    .lineLimit(1)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .background{
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(isSelected ? Theme.selected : .white)
        }
        .contentShape(Rectangle())
    }
    
    init(_ macho: Macho, isSelected: Bool) {
        self.fileName = macho.machoFileName
        self.fileSize = macho.fileSize
        self.arch = macho.header.cpuType.name
        self.isSelected = isSelected
    }
}

struct FileView: View {
    
    let file: File
    @State var selectedIndex: Int
    @State var selectedMacho: Macho
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                LazyVStack {
                    ForEach(0..<file.machos.count) { index in
                        FileViewCell(file.machos[index], isSelected: index == self.selectedIndex) .onTapGesture {
                            self.selectedIndex = index
                            self.selectedMacho = file.machos[index]
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            .fixedSize(horizontal: true, vertical: false)
            Divider()
            MachoView($selectedMacho)
        }
    }
    
    init(file: File) {
        self.file = file
        _selectedIndex = State(initialValue: 0)
        _selectedMacho = State(initialValue: file.machos.first!)
    }
}
