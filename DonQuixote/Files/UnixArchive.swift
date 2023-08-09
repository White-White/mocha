//
//  UnixArchiveReader.swift
//  mocha
//
//  Created by white on 2021/6/15.
//

import Foundation
import SwiftUI

struct UnixArchiveFileHeader {
    
    // unix archive file header format ref:
    // https://en.wikipedia.org/wiki/Ar_(Unix)
    
    let fileID: String
    var modificationTS: String?
    var ownerID: String?
    var groupID: String?
    var fileMode: String? // Octal number
    let extFileIDLengthInt: Int // non-zero when fileID is prefixed with #1/
    let contentSize: Int // size of the content file
    
    init(with fileHandle: FileHandle) throws {
        let fileIDData = (try fileHandle.assertRead(count: 16))
        guard let fileID = fileIDData.utf8String else { fatalError() /* Very unlikely */}
        
        self.modificationTS = (try fileHandle.assertRead(count: 12)).utf8String
        self.ownerID = (try fileHandle.assertRead(count: 6)).utf8String
        self.groupID = (try fileHandle.assertRead(count: 6)).utf8String
        self.fileMode = (try fileHandle.assertRead(count: 8)).utf8String
        guard let contentSizeString = (try fileHandle.assertRead(count: 10)).utf8String else { fatalError() /* Very unlikely */ }
        guard let contentSize = Int(contentSizeString.spaceRemoved) else { fatalError() /* Very unlikely */ }
        self.contentSize = contentSize
        
        // unix archive header always ends with 0x60 0x0A
        guard (try fileHandle.assertRead(count: 2)).utf8String == "`\n" else { fatalError() /* Very unlikely */ }
        
        // BSD ar stores filenames right-padded with ASCII spaces.
        // This causes issues with spaces inside filenames.
        // 4.4BSD ar stores extended filenames by placing the string "#1/" followed by the file name length in the file name field,
        // and storing the real filename in front of the data section.
        if fileID.hasPrefix("#1/") {
            guard let extFileIDLength = fileIDData.subSequence(from: 3, count: 13).utf8String else { fatalError() /* Very unlikely */ }
            guard let extFileIDLengthInt = Int(extFileIDLength.spaceRemoved) else { fatalError() /* Very unlikely */ }
            // fetch more data from the ar file dataShifter
            guard let extendedFileID = try fileHandle.assertRead(count: extFileIDLengthInt).utf8String else { fatalError() /* Very unlikely */ }
            self.fileID = extendedFileID.spaceRemoved
            self.extFileIDLengthInt = extFileIDLengthInt
        } else {
            self.fileID = fileID.spaceRemoved
            self.extFileIDLengthInt = 0
        }
    }
}

struct UnixArchive: File {
    
    static let Magic: [UInt8] = [0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E, 0x0A]
    
    let location: FileLocation
    let machoLocations: [FileLocation]
    
    init(with location: FileLocation) throws {
        self.location = location
        
        let fileHandle = try FileHandle(location)
        defer { try? fileHandle.close() }
        
        // unix archive ref: https://en.wikipedia.org/wiki/Ar_(Unix)
        // "!<arch>\n"
        let magic = try fileHandle.assertRead(count: UnixArchive.Magic.count)
        guard magic == Data(UnixArchive.Magic) else { fatalError() }
        
        var machoLocations: [FileLocation] = []
        while try fileHandle.hasAvailableData() {
            let fileHeader = try UnixArchiveFileHeader(with: fileHandle)
            let fileSize = fileHeader.contentSize - fileHeader.extFileIDLengthInt
            if fileHeader.fileID.hasPrefix("__.SYMDEF") {
                // ref: http://mirror.informatimago.com/next/developer.apple.com/documentation/DeveloperTools/Conceptual/MachORuntime/8rt_file_format/chapter_10_section_33.html
                // The first member in a static archive library is always the symbol table describing the contents of the rest of the member files.
                // This member is always called either __.SYMDEF or __.SYMDEF SORTED.
                // So we are dropping the first element
            } else {
                machoLocations.append(try location.subLocation(fileName: fileHeader.fileID, fileOffset: try fileHandle.offset(), fileSize: fileSize))
            }
            try fileHandle.skip(fileSize)
        }
        self.machoLocations = machoLocations
    }
    
}
