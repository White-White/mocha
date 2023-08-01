//
//  FatBinaryView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import Foundation
import SwiftUI

struct FatArchView: View {
    
    let fatArch: FatArch
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("arch: \(fatArch.cpu.name)")
                Text("arch (sub): \(fatArch.cpuSub.name)")
                Text("offset: \(fatArch.objectFileOffset)")
                Text("size: \(fatArch.objectFileSize) bytes")
                Spacer()
                    .frame(height: 0)
                    .frame(maxWidth: .infinity)
            }
            Button("Open", action: self.action)
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .border(.separator, width: 1)
        .background(.white)
        .frame(minWidth: 600)
    }
    
}

struct FatBinaryView: DocumentView {
    
    @Environment (\.openWindow) var openWindow
    let fatBinary: FatBinary
    
    init(_ fatBinary: FatBinary) {
        self.fatBinary = fatBinary
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(fatBinary.fatArchs, id: \.objectFileOffset) { fatArch in
                    FatArchView(fatArch: fatArch) {
                        let embeddedFileLocation = FileLocation(fatBinary.fileLocation.url,
                                                                fileName: "\(fatBinary.fileLocation.url.lastPathComponent) (\(fatArch.cpu.name))",
                                                                offset: UInt64(fatArch.objectFileOffset),
                                                                size: Int(fatArch.objectFileSize))
                        openWindow(id: FileType.fileType(from: embeddedFileLocation)!.rawValue, value: embeddedFileLocation)
                    }
                }
                Spacer()
            }
        }
    }
    
}
