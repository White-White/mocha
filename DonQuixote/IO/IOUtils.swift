//
//  IOUtils.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import Foundation

class DonFileHandle {
    
    private let fileHandle: FileHandle
    private let offsetInFile: UInt64
    private let fileSize: Int
    
    fileprivate init(forReadingFrom url: URL, offset: UInt64, fileSize: Int) throws {
        self.fileHandle = try FileHandle(forReadingFrom: url)
        self.offsetInFile = offset
        self.fileSize = fileSize
        try self.fileHandle.seek(toOffset: offset)
    }
    
    func hasAvailableData() throws -> Bool {
        return (try self.fileHandle.offset() - offsetInFile) < self.fileSize
    }
    
    func skip(_ size: Int) throws {
        try self.fileHandle.seek(toOffset: try self.fileHandle.offset() + UInt64(size))
    }
    
    func close() throws {
        try self.fileHandle.close()
    }
    
    func offset() throws -> UInt64 {
        return try self.fileHandle.offset()
    }
    
    func assertReadToEnd() throws -> Data {
        guard let data = try self.fileHandle.readToEnd() else {
            throw DonError.failToReadFileHandle
        }
        return data
    }
    
    func assertRead(count: Int) throws -> Data {
        guard let data = try self.fileHandle.read(upToCount: count), data.count == count else {
            throw DonError.failToReadFileHandle
        }
        return data
    }
    
    func assertRead(offset: UInt64, count: Int) throws -> Data {
        try self.fileHandle.seek(toOffset: offset)
        return try self.assertRead(count: count)
    }
    
}

struct FileLocation: Codable, Hashable {
    
    let url: URL
    let fileName: String
    let offset: UInt64
    let size: Int
    
    func fetchAllData() throws -> Data {
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }
        try fileHandle.seek(toOffset: self.offset)
        guard let data = try fileHandle.readToEnd() else {
            throw DonError.failToReadFileHandle
        }
        return data
    }

    func createHandle() throws -> DonFileHandle {
        try DonFileHandle(forReadingFrom: self.url, offset: self.offset, fileSize: self.size)
    }
    
    init(_ url: URL, fileName: String? = nil, offset: UInt64? = nil, size: Int? = nil) {
        self.url = url
        self.fileName = fileName ?? url.absoluteString
        self.offset = offset ?? .zero
        if let size {
            self.size = size
        } else {
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path())[.size] as? Int {
                self.size = fileSize
            } else {
                fatalError()
            }
        }
    }
    
}
