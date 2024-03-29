//
//  FatBinary.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/3.
//

import Foundation

private struct FatArch {
    
    let cpu: CPUType
    let cpuSub: CPUSubtype
    let objectFileOffset: UInt32
    let objectFileSize: UInt32
    let align: UInt32
    
    init(with data: Data) {
        self.cpu = CPUType(data.subSequence(from: 0, count: 4).UInt32.bigEndian)
        self.cpuSub = CPUSubtype(data.subSequence(from: 4, count: 4).UInt32.bigEndian, cpuType: self.cpu)
        self.objectFileOffset = data.subSequence(from: 8, count: 4).UInt32.bigEndian
        self.objectFileSize = data.subSequence(from: 12, count: 4).UInt32.bigEndian
        self.align = data.subSequence(from: 16, count: 4).UInt32.bigEndian
    }
    
}

struct FatBinary {
    
    // ref: <mach-o/fat.h>
    
//    struct fat_header {
//        uint32_t    magic;        /* FAT_MAGIC */
//        uint32_t    nfat_arch;    /* number of structs that follow */
//    };
//
//    struct fat_arch {
//        cpu_type_t    cputype;    /* cpu specifier (int) */
//        cpu_subtype_t    cpusubtype;    /* machine specifier (int) */
//        uint32_t    offset;        /* file offset to this object file */
//        uint32_t    size;        /* size of this object file */
//        uint32_t    align;        /* alignment as a power of 2 */
//    };
    
    struct FatBinaryError: Error { }
    
    static let magic: [UInt8] = [0xca, 0xfe, 0xba, 0xbe]
    
    let machoMetaDatas: [MachoMetaData]
    
    init(with fileData: Data, machoFileName: String) throws {
        
        // 0xcafebabe is also Java class files' magic number.
        // ref: https://opensource.apple.com/source/file/file-47/file/magic/Magdir/cafebabe.auto.html
        guard fileData.starts(with: FatBinary.magic) else { throw FatBinaryError() }
        
        // this value is not to be mapped to memory, so it's bytes are stored in human readable style, same with bigEndian
        // example: when the bytes are 0x00000002, indicating there are 2 archs in this fat binary, it'll be interpreted as 0x02000000 with Swift's 'load:as:' method
        let numberOfArchs = Int(fileData.subSequence(from: 4, count: 4).UInt32.bigEndian)
        
        var machoMetaDatas: [MachoMetaData] = []
        for index in 0..<numberOfArchs {
            // first 8 bytes are for magic and 'number of archs'
            // struct fat_arch has 20 bytes
            let fatArchData = fileData.subSequence(from: 8 + (index * 20), count: 20)
            let farArch = FatArch(with: fatArchData)
            
            let subFileDataRaw = fileData.subSequence(from: Int(farArch.objectFileOffset), count: Int(farArch.objectFileSize))
            machoMetaDatas.append(contentsOf: try MochaDocument(fileName: machoFileName, fileData: Data(subFileDataRaw)).machoMetaDatas)
        }
        self.machoMetaDatas = machoMetaDatas
    }
    
}
