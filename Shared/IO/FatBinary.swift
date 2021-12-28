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
    
    init(with data: SmartData) {
        self.cpu = CPUType(data.truncated(from: 0, length: 4).raw.UInt32.bigEndian)
        self.cpuSub = CPUSubtype(data.truncated(from: 4, length: 4).raw.UInt32.bigEndian, cpuType: self.cpu)
        self.objectFileOffset = data.truncated(from: 8, length: 4).raw.UInt32.bigEndian
        self.objectFileSize = data.truncated(from: 12, length: 4).raw.UInt32.bigEndian
        self.align = data.truncated(from: 16, length: 4).raw.UInt32.bigEndian
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
    
    private let numberOfArchs: UInt32
    private let fatArchs: [FatArch]
    let machos: [Macho]
    
    init(with fileData: SmartData, machoFileName: String) throws {
        // this value is not to be mapped to memory, so it's bytes are stored in human readable style, same with bigEndian
        // example: when the bytes are 0x00000002, indicating there are 2 archs in this fat binary, it'll be interpreted as 0x02000000 with Swift's 'load:as:' method
        self.numberOfArchs = fileData.truncated(from: 4, length: 4).raw.UInt32.bigEndian
        
        var fatArchs: [FatArch] = []
        var machos: [Macho] = []
        for index in 0..<Int(self.numberOfArchs) {
            // first 8 bytes are for magic and 'number of archs'
            // struct fat_arch has 20 bytes
            let fatArchData = fileData.truncated(from: 8 + (index * 20), length: 20)
            let farArch = FatArch(with: fatArchData)
            fatArchs.append(farArch)
            
            let machoRealData = fileData.truncated(from: Data.Index(farArch.objectFileOffset), length: Data.Index(farArch.objectFileSize)).raw
            let macho = Macho(with: SmartData(machoRealData), machoFileName: machoFileName)
            machos.append(macho)
        }
        self.fatArchs = fatArchs
        self.machos = machos
    }
    
}
