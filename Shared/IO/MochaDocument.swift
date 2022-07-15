//
//  MochaDocument.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/8.
//

import SwiftUI
import UniformTypeIdentifiers

struct MachoMetaData: Identifiable, Equatable {
    
    struct MachoMetaDataError: Error {  }
    
    static func == (lhs: MachoMetaData, rhs: MachoMetaData) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    
    let fileName: String
    let is64Bit: Bool
    
    let machoData: Data
    var machoFileSize: Int { machoData.count }
    let machoHeader: MachoHeader
    var macho: Macho { Macho(with: machoData, machoFileName: fileName, machoHeader: machoHeader) }
    
    init(fileName: String, machoData: Data) throws {
        self.fileName = fileName
        self.machoData = machoData
        let is64Bit: Bool
        if machoData.starts(with: [0xce, 0xfa, 0xed, 0xfe]) {
            is64Bit = false
        } else if machoData.starts(with: [0xcf, 0xfa, 0xed, 0xfe]) {
            is64Bit = true
        } else {
            throw MachoMetaDataError()
        }
        self.is64Bit = is64Bit
        self.machoHeader = MachoHeader(from: machoData, is64Bit: is64Bit)
    }
    
}

struct MochaDocument {
    
    struct MochaDocumentError: Error { }
    
    let fileName: String
    let fileSize: Int
    let machoMetaDatas: [MachoMetaData]
    
    init(fileURL: URL) throws {
        let fileData = try Data(contentsOf: fileURL)
        try self.init(fileName: fileURL.lastPathComponent, fileData: fileData)
    }
    
    init(fileName: String, fileData: Data) throws {
        self.fileName = fileName
        self.fileSize = fileData.count
        
        if let unixArchive = try? UnixArchive(with: fileData) {
            self.machoMetaDatas = unixArchive.machoMetaDatas
        } else if let fatBinary = try? FatBinary(with: fileData, machoFileName: fileName) {
            self.machoMetaDatas = fatBinary.machoMetaDatas
        } else if let unixBinary = try? MachoMetaData(fileName: fileName, machoData: fileData) {
            self.machoMetaDatas = [unixBinary]
        } else {
            throw MochaDocumentError()
        }
    }
    
}
