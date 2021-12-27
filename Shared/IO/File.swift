//
//  File.swift
//  mocha
//
//  Created by white on 2021/12/03.
//

import Foundation

enum MagicType {
    case ar // unix archive ref: https://en.wikipedia.org/wiki/Ar_(Unix)
    case fat // fat binary ref: https://en.wikipedia.org/wiki/Fat_binary
    case macho32
    case macho64

    init?(_ fileData: SmartData) {
        if fileData.starts(with: [0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E, 0x0A]) {
            // "!<arch>\n"
            self = .ar
        } else if fileData.starts(with: [0xca, 0xfe, 0xba, 0xbe]) {
            // 0xcafebabe is also Java class files' magic number.
            // ref: https://opensource.apple.com/source/file/file-47/file/magic/Magdir/cafebabe.auto.html
            self = .fat
        } else if fileData.starts(with: [0xce, 0xfa, 0xed, 0xfe]) {
            self = .macho32
        } else if fileData.starts(with: [0xcf, 0xfa, 0xed, 0xfe]) {
            self = .macho64
        } else {
            return nil
        }
    }
    
    var readable: String {
        switch self {
        case .ar:
            return "Unix Archive's File Magic"
        case .fat:
            return "Fat Binary's File Magic"
        case .macho32:
            return "Mach-O(32bit)'s File Magic"
        case .macho64:
            return "Mach-O(64bit)'s File Magic"
        }
    }
}

struct File {
    
    let fileURL: URL
    var fileSize: Int { fileData.count }
    let fileData: SmartData
    let machos: [Macho]
    
    init(with filePath: String) throws {
        try self.init(with: URL(fileURLWithPath: filePath))
    }
    
    init(with fileURL: URL) throws {
        
        self.fileURL = fileURL
        let fileData = SmartData(try Data(contentsOf: fileURL))
        self.fileData = fileData
        
        guard let magicType = MagicType(fileData) else { throw MochaError(.unknownMagicType) }
        switch magicType {
        case .ar:
            let ar = try UnixArchive(with: fileData)
            self.machos = ar.machos
        case .fat:
            let machoName = fileURL.lastPathComponent
            self.machos = (try FatBinary(with: fileData, machoFileName: machoName)).machos
        case .macho32, .macho64:
            let machoName = fileURL.lastPathComponent
            self.machos = [Macho(with: fileData, machoFileName: machoName)]
        }
        
    }
}
