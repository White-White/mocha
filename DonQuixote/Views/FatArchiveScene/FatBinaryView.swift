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
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                HStack {
                    Text("File path:").bold()
                    Text(fatBinary.location.fileURL.relativePath)
                    Button("Show in Finder") {
                        NSWorkspace.shared.open(
                            URL(
                                fileURLWithPath: fatBinary.location.fileURL.deletingLastPathComponent().path(),
                                isDirectory: true
                            )
                        )
                    }
                }
                HStack {
                    Text("File type:").bold()
                    Text(FileType.fat.name)
                        .padding(.bottom, 4)
                }
            }
            
            VStack(alignment: .leading) {
                List(self.allMachoFileLocations(), id: \.fileOffset) { machoFileLocation in
                    MachoItemView(machoLocation: machoFileLocation)
                }
                .listStyle(.plain)
            }
        }
        .padding(16)
        .background(.white)
    }
    
    func allMachoFileLocations() -> [FileLocation] {
        return self.fatBinary.fatArchs.flatMap { self.machoFileLocations(for: $0) }
    }
    
    func machoFileLocations(for fatArch: FatArch) -> [FileLocation] {
        let subFileLocation = try! fatBinary.location.subLocation(fileName: "\(fatBinary.location.fileName) (\(fatArch.cpu.name))",
                                                                  fileOffset: UInt64(fatArch.objectFileOffset),
                                                                  fileSize: Int(fatArch.objectFileSize))
        switch subFileLocation.fileType {
        case .ar:
            return (try! UnixArchive(with: subFileLocation)).machoLocations
        case .macho:
            return [subFileLocation]
        default:
            fatalError()
        }
    }
    
}
