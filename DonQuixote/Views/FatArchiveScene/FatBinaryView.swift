//
//  FatBinaryView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import SwiftUI

struct FatBinaryView: DocumentView {
    
    let fatBinary: FatBinary
    
    init(_ fatBinary: FatBinary) {
        self.fatBinary = fatBinary
    }
    
    var body: some View {
        MachoContainerView(mainFileLocation: fatBinary.location, machoFileLocations: self.allMachoFileLocations())
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
