//
//  KnownFileType.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import Foundation
import UniformTypeIdentifiers

enum KnownFileType: String {
    
    case ar
    case dylib
    case unixExecutable
    case framework
    case ipa
    case app
    
    init?(_ contentType: UTType) {
        switch contentType {
        case UTType(filenameExtension: "a"):
            self = .ar
        case UTType(filenameExtension: "dylib"):
            self = .dylib
        case .unixExecutable:
            self = .unixExecutable
        case UTType(filenameExtension: "ipa"):
            self = .ipa
        default:
            return nil
        }
    }
    
    init?(_ fileURL: URL) {
        if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .contentTypeKey]) {
            if let isDirectory = resourceValues.isDirectory,
                isDirectory {
                return nil
            }
            if let isRegularFile = resourceValues.isRegularFile,
                !isRegularFile {
                return nil
            }
            if let contentType = resourceValues.contentType {
                self.init(contentType)
                return
            }
        }
        return nil
    }
    
    static func knowsFile(with fileURL: URL) -> Bool {
        return KnownFileType(fileURL) != nil
    }
    
}
