//
//  IOUtils.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import Foundation

class FileHandle {
    
    private let fileHandle: Foundation.FileHandle
    private let offsetInFile: UInt64
    private let fileSize: Int
    
    convenience init(_ location: FileLocation) throws {
        try self.init(location.fileURL, fileSize: location.fileSize, offset: location.fileOffset)
    }
    
    init(_ url: URL, fileSize: Int, offset: UInt64) throws {
        self.fileHandle = try Foundation.FileHandle(forReadingFrom: url)
        self.fileSize = fileSize
        self.offsetInFile = offset
        if offset.isNotZero { try self.fileHandle.seek(toOffset: offset) }
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
    
    func assertReadAndReset(count: Int) throws -> Data {
        let originalOffset = try fileHandle.offset()
        let data = try self.assertRead(count: count)
        try self.fileHandle.seek(toOffset: originalOffset)
        return data
    }
    
    func assertRead(offset: UInt64, count: Int) throws -> Data {
        try self.fileHandle.seek(toOffset: offset)
        return try self.assertRead(count: count)
    }
    
}


