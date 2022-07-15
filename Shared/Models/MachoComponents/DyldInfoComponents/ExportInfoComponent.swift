//
//  ExportInfoInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/14.
//

import Foundation

//#define EXPORT_SYMBOL_FLAGS_STATIC_RESOLVER            0x20
// FIXME: flag usage of EXPORT_SYMBOL_FLAGS_STATIC_RESOLVER is not open sourced yet in dyld

struct ExportSymbolFlag {
    enum Kind {
        case regular
        case threadLocal
        case absolute
        
        var readable: String {
            switch self {
            case .regular:
                return "EXPORT_SYMBOL_FLAGS_KIND_REGULAR"
            case .threadLocal:
                return "EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL"
            case .absolute:
                return "EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE"
            }
        }
    }
    
    let kind: Kind
    let isReExport: Bool
    let isWeakDef: Bool
    let isStubAndResolver: Bool
    let byteCount: Int
    
    init(flags: LEB128) {
        let flagsRawValue = flags.rawValue
        self.byteCount = flags.byteCount
        
        let kindRawValue = flagsRawValue & 0x03 // EXPORT_SYMBOL_FLAGS_KIND_MASK
        switch kindRawValue {
        case 0x00: // EXPORT_SYMBOL_FLAGS_KIND_REGULAR
            self.kind = .regular
        case 0x01: // EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL
            self.kind = .threadLocal
        case 0x02: // EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE
            self.kind = .absolute
        default:
            fatalError() // unknown export info kind
        }
        
        self.isReExport = flagsRawValue & 0x08 /* EXPORT_SYMBOL_FLAGS_REEXPORT */ != 0
        self.isWeakDef = flagsRawValue & 0x04 /* EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION */ != 0
        self.isStubAndResolver = flagsRawValue & 0x10 /* EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER */ != 0
    }
    
    var flagsDescription: String {
        var ret: [String] = []
        if self.isReExport { ret.append("EXPORT_SYMBOL_FLAGS_REEXPORT") }
        if self.isWeakDef { ret.append("EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION") }
        if self.isStubAndResolver { ret.append("EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER") }
        return ret.joined(separator: "\n")
    }
}


struct ExportInfoNodeEdge {
    let edgeName: CString
    let offset: LEB128
}

class ExportInfoNode {
    let startOffsetInMacho: Int
    let accumulatedString: String
    
    let terminalSize: LEB128
    let flags: ExportSymbolFlag?
    let leb128Array: [LEB128]?
    var reExportedSymbolName: CString?
    
    let edgesCount: LEB128
    let edges: [ExportInfoNodeEdge]
    
    init(startOffsetInMacho: Int,
         accumulatedString: String,
         terminalSize: LEB128,
         flags: ExportSymbolFlag?,
         leb128Array: [LEB128]?,
         reExportedSymbolName: CString?,
         edgesCount: LEB128,
         edges: [ExportInfoNodeEdge]) {
        
        self.startOffsetInMacho = startOffsetInMacho
        self.accumulatedString = accumulatedString
        self.terminalSize = terminalSize
        self.flags = flags
        self.leb128Array = leb128Array
        self.reExportedSymbolName = reExportedSymbolName
        self.edgesCount = edgesCount
        self.edges = edges
    }
    
    var transIations: [Translation] {
        
        var transIations: [Translation] = []
        
        transIations.append(Translation(description: "Trie Node Full Name", explanation: accumulatedString, bytesCount: .zero, explanationStyle: .extraDetail))
        transIations.append(Translation(description: "Terminal Size", explanation: "\(terminalSize.rawValue)", bytesCount: terminalSize.byteCount))
        
        if let flags = flags,
            let leb128Array = leb128Array {
            
            transIations.append(Translation(description: "Kind", explanation: flags.kind.readable,
                                            bytesCount: flags.byteCount,
                                            extraDescription: "Flags", extraExplanation: flags.flagsDescription))
            
            for leb in leb128Array {
                transIations.append(Translation(description: "LEB", explanation: leb.rawValue.hex, bytesCount: leb.byteCount))
            }
            
            if let reExportedSymbolName = reExportedSymbolName {
                transIations.append(Translation(description: "ReExported Symbol Name", explanation: reExportedSymbolName.rawValue, bytesCount: reExportedSymbolName.byteCount))
            }
        }
        
        transIations.append(Translation(description: "Number of Edges", explanation: "\(edgesCount.rawValue)", bytesCount: edgesCount.byteCount, hasDivider: edges.isEmpty))
        
        
        for edge in self.edges {
            transIations.append(Translation(description: "Edge Name", explanation: edge.edgeName.rawValue, bytesCount: edge.edgeName.byteCount))
            transIations.append(Translation(description: "Edge Offset", explanation: edge.offset.rawValue.hex, bytesCount: edge.offset.byteCount))
        }
        
        return transIations
    }
}

class ExportInfoComponent: MachoComponent {
    
    let exportInfoNodes: [ExportInfoNode]
    
    init(_ data: Data, title: String, subTitle: String, is64Bit: Bool) {
        let root = ExportInfoComponent.generateNode(from: data, for: nil, parentNode: nil)
        self.exportInfoNodes = ExportInfoComponent.allNodes(from: root, in: data).sorted { $0.startOffsetInMacho < $1.startOffsetInMacho }
        super.init(data, title: title, subTitle: subTitle)
    }

    override func createTranslations() -> [Translation] {
        return self.exportInfoNodes.flatMap { $0.transIations }
    }
    
    private static func allNodes(from root: ExportInfoNode, in data: Data) -> [ExportInfoNode] {
        var ret: [ExportInfoNode] = [root]
        for childNode in (root.edges.map { generateNode(from: data, for: $0, parentNode: root) }) {
            ret.append(contentsOf: allNodes(from: childNode, in: data))
        }
        return ret
    }
    
    private static func generateNode(from data: Data, for edge: ExportInfoNodeEdge?, parentNode: ExportInfoNode?) -> ExportInfoNode {
        let startOffset = Int(edge?.offset.rawValue ?? 0)
        var endOffset = startOffset
        
        let accumulatedString = (parentNode?.accumulatedString ?? "") + (edge?.edgeName.rawValue ?? "")
        
        let terminalSizeLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += terminalSizeLEB.byteCount

        var retFlags: ExportSymbolFlag?
        var leb128Array: [LEB128]?
        var reExportedSymbolName: CString?
        if terminalSizeLEB.rawValue != 0 { // this node contains an exported symbol
            let flagsLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += flagsLEB.byteCount
            let flags = ExportSymbolFlag(flags: flagsLEB); retFlags = flags
            if flags.isReExport {
                let dylibOrdinalLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += dylibOrdinalLEB.byteCount
                let nameRead = InterpreterUtils.readUTF8String(in: data, at: endOffset); endOffset += nameRead.byteCount
                leb128Array = [dylibOrdinalLEB]
                reExportedSymbolName = nameRead
            } else if flags.isStubAndResolver {
                let stubOffsetLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += stubOffsetLEB.byteCount
                let resolverOffsetLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += resolverOffsetLEB.byteCount
                leb128Array = [stubOffsetLEB, resolverOffsetLEB]
            } else {
                let imageOffsetLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += imageOffsetLEB.byteCount
                leb128Array = [imageOffsetLEB]
            }
        }
        
        let edgesCountLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += edgesCountLEB.byteCount
        var edges: [ExportInfoNodeEdge] = []
        for _ in 0..<edgesCountLEB.rawValue {
            let edgeNameString = InterpreterUtils.readUTF8String(in: data, at: endOffset, spacedRemoved: true); endOffset += edgeNameString.byteCount
            let childNodeOffsetLEB = InterpreterUtils.readULEB128(in: data, at: endOffset); endOffset += childNodeOffsetLEB.byteCount
            edges.append(ExportInfoNodeEdge(edgeName: edgeNameString, offset: childNodeOffsetLEB))
        }
        
        return ExportInfoNode(startOffsetInMacho: data.startIndex + startOffset,
                              accumulatedString: accumulatedString,
                              terminalSize: terminalSizeLEB,
                              flags: retFlags,
                              leb128Array: leb128Array,
                              reExportedSymbolName: reExportedSymbolName,
                              edgesCount: edgesCountLEB,
                              edges: edges)
    }
}
