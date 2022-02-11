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

    init?(_ fileData: Data) {
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
    
    var isMachoFile: Bool {
        return self == .macho32 || self == .macho64
    }
}

struct File {
    
    let fileName: String
    let fileSize: Int
    let machos: [Macho]
    
    init(with fileURL: URL) {
        let fileName = fileURL.lastPathComponent
        guard let fileData = try? Data(contentsOf: fileURL) else { fatalError() }
        self.init(with: fileName, fileData: fileData)
    }
    
    init(with fileName: String, fileData: Data) {
        self.fileName = fileName
        self.fileSize = fileData.count
        guard let magicType = MagicType(fileData) else { fatalError() /* Unknown Magic */ }
        switch magicType {
        case .ar:
            let ar = UnixArchive(with: fileData)
            self.machos = ar.machos
        case .fat:
            self.machos = FatBinary(with: fileData, machoFileName: fileName).machos
        case .macho32, .macho64:
            self.machos = [Macho(with: fileData, machoFileName: fileName)]
        }
    }
}
