//
//  FatBinaryView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import SwiftUI

struct FatBinaryView: DocumentView {
    
    @Environment (\.openWindow) var openWindow
    let fatBinary: FatBinary
    
    init(_ fatBinary: FatBinary) {
        self.fatBinary = fatBinary
    }
    
    var body: some View {
        NavigationStack() {
            VStack(alignment: .leading) {
                DocumentInfoView(location: fatBinary.location, fileType: .fat)
                List(fatBinary.fatArchs, id: \.objectFileOffset) { fatArch in
                    NavigationLink(fatArch.cpu.name, value: self.fileLocation(for: fatArch))
                }
                .listStyle(.plain)
                .navigationDestination(for: FileLocation.self) { location in
                    switch location.fileType {
                    case .ar:
                        UnixArchiveView(try! UnixArchive(with: location))
                    default:
                        fatalError()
                    }
                }
            }
        }
        .toolbar { Spacer() }
    }
    
    func fileLocation(for fatArch: FatArch) -> FileLocation {
        let location = try! fatBinary.location.subLocation(fileName: "\(fatBinary.location.fileName) (\(fatArch.cpu.name))",
                                                          fileOffset: UInt64(fatArch.objectFileOffset),
                                                          fileSize: Int(fatArch.objectFileSize))
        return location
    }
    
    
    
}
