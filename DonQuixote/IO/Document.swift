//
//  Document.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import Foundation

enum DocumentOpenResult<T> {
    case success(T)
    case error(Error)
}

struct Document {
    
    let fileName: String
    let fileSize: Int
    let fileData: Data
    
    init(fileURL: URL) throws {
        let fileData = try Data(contentsOf: fileURL)
        self.fileName = fileURL.lastPathComponent
        self.fileSize = fileData.count
        self.fileData = fileData
    }
    
    func openAsMacho() throws -> Macho {
        let is64Bit: Bool
        let magic = Data(self.fileData[0..<4]).UInt32
        if magic == 0xfeedfacf /* #define MH_MAGIC_64 0xfeedfacf */ {
            is64Bit = true
        } else if magic == 0xfeedface /* #define MH_MAGIC 0xfeedface */  {
            is64Bit = false
        } else {
            fatalError() /* what the hell is going on */
        }
        let machoHeader = MachoHeader(from: fileData, is64Bit: is64Bit)
        let macho = Macho(with: fileData, machoFileName: self.fileName, machoHeader: machoHeader)
        return macho
    }
    
    static func openMacho(fileURL: URL?) -> DocumentOpenResult<Macho> {
        do {
            guard let fileURL else {
                throw DonError.invalidFileURL
            }
            let macho = try Document(fileURL: fileURL).openAsMacho()
            return .success(macho)
        } catch let error {
            return .error(error)
        }
    }
    
    static func openIPA(fileURL: URL?) -> DocumentOpenResult<IPA> {
        do {
            guard let fileURL else {
                throw DonError.invalidFileURL
            }
            let ipa = try IPA(fileURL: fileURL)
            return .success(ipa)
        } catch let error {
            return .error(error)
        }
    }
    
}
