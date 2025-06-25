//
//  CodeSignature.swift
//  DonQuixote
//
//  Created by white on 2025/6/18.
//

import Foundation

//typedef struct __BlobIndex {
//    uint32_t type;                                  /* type of entry */
//    uint32_t offset;                                /* offset of entry */
//} CS_BlobIndex

//typedef struct __SC_SuperBlob {
//    uint32_t magic;                                 /* magic number */
//    uint32_t length;                                /* total length of SuperBlob */
//    uint32_t count;                                 /* number of index entries following */
//    CS_BlobIndex index[];                   /* (count) entries */
//    /* followed by Blobs in no particular order as indicated by offsets in index */
//} CS_SuperBlob

//enum BlobType: UInt32 {
//    
//}

struct BlobIndex {
    let type: UInt32
    let offset: Int
    init(shifter: inout DataShifter) {
        self.type = shifter.shift(.doubleWords).UInt32
        self.offset = Int(shifter.shift(.doubleWords).UInt32)
    }
}

struct SuperBlob {
    let magic: Int
    let length: Int
    let count: Int
    let blobIndexs: [BlobIndex]
    init(shifter: inout DataShifter) {
        self.magic = Int(shifter.shift(.doubleWords).UInt32)
        self.length = Int(shifter.shift(.doubleWords).UInt32)
        let count = Int(shifter.shift(.doubleWords).UInt32)
        self.count = count
        var blobIndexs: [BlobIndex] = []
        for _ in 0..<count {
            let blobIndex = BlobIndex(shifter: &shifter)
            blobIndexs.append(blobIndex)
        }
        self.blobIndexs = blobIndexs
    }
}

struct CodeSignatureData {
    
    let superBlob: SuperBlob
    
    init(data: Data) {
        var shifter = DataShifter(data)
        self.superBlob = SuperBlob(shifter: &shifter)
    }
    
}

class CodeSignature: MachoPortion, @unchecked Sendable {
    
    override init(_ data: Data, title: String, subTitle: String?) {
        super.init(data, title: title, subTitle: subTitle)
    }
    
    override func initialize() async -> any AsyncInitializeResult {
//        return CodeSignatureData(data: self.data)
        return "a"
    }
    
    override func translate(initializeResult: any AsyncInitializeResult) async -> any AsyncTranslationResult {
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
//        translationGroup.addTranslation(definition: <#T##String?#>, humanReadable: <#T##String#>, translationType: <#T##TranslationType#>)
        return TranslationGroups([])
    }
    
    
}
