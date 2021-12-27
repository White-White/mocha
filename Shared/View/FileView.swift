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
    @State var selectedMacho: Macho?
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                VStack(alignment:.leading, spacing: 4) {
                    ForEach(file.machos) { macho in
                        FileViewCell(macho, isSelected: self.selectedMacho == macho) .onTapGesture {
                            self.selectedMacho = macho
                            
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            .fixedSize(horizontal: true, vertical: false)
            
            Divider()
            
            if let selectedMacho = selectedMacho {
                MachoView(selectedMacho)
            } else {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Text("Select a file")
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
}

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
        FileView(file: try! File(with: "/Users/white/Desktop/VideoToolBox"))
    }
}
