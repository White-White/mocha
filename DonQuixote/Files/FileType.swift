//
//  FileType.swift
//  DonQuixote
//
//  Created by white on 2023/8/9.
//

import Foundation
import UniformTypeIdentifiers

enum FileType: String, Codable {
    
    case ar
    case fat
    case macho
    case framework
    case ipa
    case app
    
    var name: String {
        switch self {
        case .ar:
            return "Unix Archive"
        case .fat:
            return "Fat Binary"
        case .macho:
            return "Macho"
        case .framework:
            return "Framework"
        case .ipa:
            return "IPA"
        case .app:
            return "App"
        }
    }
    
    init(from handle: FileHandle) throws {
        
        let knownMagics: [(FileType, [UInt8])] = [
            (.fat, FatBinary.Magic),
            (.ar, UnixArchive.Magic),
            (.macho, Macho.Magic32),
            (.macho, Macho.Magic64)
        ]
        
        guard let matchedType: FileType = (knownMagics.reduce(nil) { matchedType, pair in
            if let matchedType {
                return matchedType
            } else {
                let magic = pair.1
                let type = pair.0
                if let matchData = try? handle.assertReadAndReset(count: magic.count) {
                    if matchData == Data(magic) {
                        return type
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            }
        }) else {
            throw DonError.unknownFile
        }
        
        self = matchedType
    }
    
}
