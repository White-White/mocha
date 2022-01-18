//
//  EncryptionInfo.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

//struct encryption_info_command_64 {
//   uint32_t    cmd;        /* LC_ENCRYPTION_INFO_64 */
//   uint32_t    cmdsize;    /* sizeof(struct encryption_info_command_64) */
//   uint32_t    cryptoff;    /* file offset of encrypted range */
//   uint32_t    cryptsize;    /* file size of encrypted range */
//   uint32_t    cryptid;    /* which enryption system,
//                   0 means not-encrypted yet */
//   uint32_t    pad;        /* padding to make this struct's size a multiple
//                   of 8 bytes */
//};

class LCEncryptionInfo: LoadCommand {
    
    let cryptoOffset: UInt32
    let cryptoSize: UInt32
    let cryptoID: UInt32
    let pad: UInt32?
    
    required init(with type: LoadCommandType, data: DataSlice, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(machoDataSlice: data).skip(.quadWords)
        
        self.cryptoOffset =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: DataInterpreterPreset.UInt32) { offset in TranslationItemContent(description: "Crypto File Offset", explanation: offset.hex) }
        
        self.cryptoSize =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: DataInterpreterPreset.UInt32) { size in TranslationItemContent(description: "Crypto File Size", explanation: "\(size)") }
        
        self.cryptoID =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: DataInterpreterPreset.UInt32) { id in TranslationItemContent(description: "Crypto ID", explanation: "\(id)") }
        
        if type == .encryptionInfo64 {
            self.pad =
            translationStore.translate(next: .doubleWords,
                                       dataInterpreter: DataInterpreterPreset.UInt32) { pad in TranslationItemContent(description: "Crypto Pad", explanation: "\(pad)") }
        } else {
            self.pad = nil
        }
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
    
}
