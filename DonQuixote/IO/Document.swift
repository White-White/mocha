//
//  Document.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import Foundation
import UniformTypeIdentifiers

protocol Document {
    init(with fileLocation: FileLocation) throws
}

enum FileType: String {
    
    case ar
    case fat
    case dylib
    case unixExecutable
    case framework
    case ipa
    case app
    
    static func canOpen(_ url: URL) -> Bool {
        return self.fileType(from: FileLocation(url)) != nil
    }
    
    static func fileType(from fileLocation: FileLocation) -> FileType? {
        
        if fileLocation.offset == .zero {
            if let resourceValues = try? fileLocation.url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .contentTypeKey]) {
                if let isDirectory = resourceValues.isDirectory,
                    isDirectory {
                    return nil
                }
                if let isRegularFile = resourceValues.isRegularFile,
                    !isRegularFile {
                    return nil
                }
                if let contentType = resourceValues.contentType {
                    switch contentType {
                    case UTType(filenameExtension: "a"):
                        return .ar
                    case UTType(filenameExtension: "dylib"):
                        return .dylib
                    case .unixExecutable:
                        return .unixExecutable
                    default:
                        break
                    }
                }
            }
        }
        
        let knownMagics: [FileType: [UInt8]] = [
            .fat: FatBinary.magic,
            .ar: UnixArchive.magic
        ]
        
        let matchedType: FileType? = knownMagics.reduce(nil) { matchedType, pair in
            if let matchedType {
                return matchedType
            } else {
                if let handle = try? fileLocation.createHandle() {
                    defer { try? handle.close() }
                    if let matchData = try? handle.assertRead(count: pair.1.count) {
                        if matchData == Data(pair.1) {
                            return pair.0
                        } else {
                            return nil
                        }
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            }
        }
        
        return matchedType
    }
    
}
