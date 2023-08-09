//
//  DocumentLocation.swift
//  DonQuixote
//
//  Created by white on 2023/8/9.
//

import Foundation

struct FileLocation: Codable, Hashable {
    
    let fileURL: URL
    let fileName: String
    let fileType: FileType
    
    let isSubFile: Bool
    let fileOffset: UInt64
    let fileSize: Int
    
    init(_ url: URL) throws {
        let resourceInfo = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .contentTypeKey, .fileSizeKey])
        guard let fileSize = resourceInfo.fileSize else { fatalError() }
        let fileOffset: UInt64 = .zero
        let fileHandle = try FileHandle(url, fileSize: fileSize, offset: fileOffset)
        defer { try? fileHandle.close() }
        let fileType = try FileType(from: fileHandle)
        self.init(url, fileName: url.lastPathComponent, fileOffset: fileOffset, fileSize: fileSize, fileType: fileType, isSubFile: false)
    }
    
    private init(_ url: URL, fileName: String, fileOffset: UInt64, fileSize: Int, fileType: FileType, isSubFile: Bool) {
        self.fileURL = url
        self.fileName = fileName
        self.fileOffset = fileOffset
        self.fileSize = fileSize
        self.fileType = fileType
        self.isSubFile = isSubFile
    }
    
    func subLocation(fileName: String, fileOffset: UInt64, fileSize: Int) throws -> FileLocation {
        let fileHandle = try FileHandle(self.fileURL, fileSize: fileSize, offset: fileOffset)
        defer { try? fileHandle.close() }
        let fileType = try FileType(from: fileHandle)
        return FileLocation(self.fileURL, fileName: fileName, fileOffset: fileOffset, fileSize: fileSize, fileType: fileType, isSubFile: true)
    }
    
}
