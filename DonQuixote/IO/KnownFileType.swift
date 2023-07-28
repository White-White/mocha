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
            // TODO: support ipa
//        case UTType(filenameExtension: "ipa"):
//            self = .ipa
        default:
            return nil
        }
    }
    
}
