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
    
    let numberOfTranslationItems: Int
    lazy var transItems: [TranslationItem] = {
        var transItems: [TranslationItem] = []
        
        let terminalSizeRange = Utils.makeRange(start: startOffsetInMacho, length: terminalSize.byteCount)
        transItems.append(TranslationItem(sourceDataRange: startOffsetInMacho..<startOffsetInMacho+terminalSize.byteCount,
                                          content: TranslationItemContent(description: "Terminal Size", explanation: "\(terminalSize.rawValue)")))
        
        if let flags = flags,
            let leb128Array = leb128Array {
            
            let flagsRange = Utils.range(after: terminalSizeRange, length: flags.byteCount)
            transItems.append(TranslationItem(sourceDataRange: flagsRange,
                                              content: TranslationItemContent(description: "Kind", explanation: flags.kind.readable)))
            
            transItems.append(TranslationItem(sourceDataRange: flagsRange,
                                              content: TranslationItemContent(description: "Flags", explanation: flags.flagsDescription)))
            
            var rangeOfLastLEB: Range<Int>?
            for leb in leb128Array {
                let lastRange = rangeOfLastLEB ?? flagsRange
                let thisLEBRange = Utils.range(after: lastRange, length: leb.byteCount)
                transItems.append(TranslationItem(sourceDataRange: thisLEBRange,
                                                  content: TranslationItemContent(description: "LEB", explanation: leb.rawValue.hex)))
                rangeOfLastLEB = thisLEBRange
            }
            
            if let reExportedSymbolName = reExportedSymbolName {
                let lastRange = rangeOfLastLEB ?? flagsRange
                let thisCStringRange = Utils.range(after: lastRange, length: reExportedSymbolName.byteCount)
                transItems.append(TranslationItem(sourceDataRange: flagsRange,
                                                  content: TranslationItemContent(description: "ReExported Symbol Name",
                                                                                  explanation: reExportedSymbolName.rawValue)))
            }
        }
        
        let edgeCountRnage = Utils.range(after: terminalSizeRange, distance: Int(terminalSize.rawValue), length: edgesCount.byteCount)
        transItems.append(TranslationItem(sourceDataRange: edgeCountRnage,
                                          content: TranslationItemContent(description: "Number of Edges", explanation: "\(edgesCount.rawValue)",
                                                                          hasDivider: edges.isEmpty)))
        
        var rangeOfLastEdge: Range<Int>?
        for index in edges.indices {
            let edge = edges[index]
            let lastRange = rangeOfLastEdge ?? edgeCountRnage
            let edgeNameRange = Utils.range(after: lastRange, length: edge.edgeName.byteCount)
            transItems.append(TranslationItem(sourceDataRange: edgeNameRange,
                                              content: TranslationItemContent(description: "Edge Name",
                                                                              explanation: edge.edgeName.rawValue)))
            
            let edgeOffsetRange = Utils.range(after: edgeNameRange, length: edge.offset.byteCount)
            transItems.append(TranslationItem(sourceDataRange: edgeOffsetRange,
                                              content: TranslationItemContent(description: "Edge Offset",
                                                                              explanation: edge.offset.rawValue.hex,
                                                                              hasDivider: index == edges.count - 1)))
            rangeOfLastEdge = edgeOffsetRange
        }
        
        transItems.insert(TranslationItem(sourceDataRange: 0..<0,
                                          content: TranslationItemContent(description: "Trie Node Full Name",
                                                                          explanation: accumulatedString,
                                                                          explanationStyle: .extraDetail)),
                          at: .zero)
        
        return transItems
    }()
    
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
        
        var numberOfTranslationItems = 2 + edges.count * 2 + 1
        if flags != nil { numberOfTranslationItems += 2 }
        if leb128Array != nil { numberOfTranslationItems += leb128Array!.count }
        if reExportedSymbolName != nil { numberOfTranslationItems += 1 }
        self.numberOfTranslationItems = numberOfTranslationItems
    }
}

struct ExportInfoContainer {
    
    let nodes: [ExportInfoNode]
    let numberOfAccumulatedTransItems: [Int]
    var numberOfTransItemsTotal: Int {
        return numberOfAccumulatedTransItems.last!
    }
    
    init(nodes: [ExportInfoNode]) {
        self.nodes = nodes
        self.numberOfAccumulatedTransItems = nodes.reduce([], {
            return $0 + [($0.last ?? 0) + $1.numberOfTranslationItems]
        })
    }
}

class ExportInfoComponent: MachoLazyComponent<ExportInfoContainer> {
    
    override var shouldPreload: Bool { true }
    
    override func generatePayload() -> ExportInfoContainer {
        let rawData = self.data
        let root = generateNode(from: rawData, for: nil, parentNode: nil)
        let allNodes = allNodes(from: root, in: rawData).sorted { $0.startOffsetInMacho < $1.startOffsetInMacho }
        return ExportInfoContainer(nodes: allNodes)
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.numberOfTransItemsTotal
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let index = indexPath.section
        for element in self.payload.numberOfAccumulatedTransItems.enumerated() {
            let exportInfo = self.payload.nodes[element.offset]
            if index < element.element {
                let numberOfTransItemsBeforeCurrent = element.element - exportInfo.numberOfTranslationItems
                return exportInfo.transItems[index - numberOfTransItemsBeforeCurrent]
            }
        }
        fatalError()
    }
    
    private func allNodes(from root: ExportInfoNode, in data: Data) -> [ExportInfoNode] {
        var ret: [ExportInfoNode] = [root]
        for childNode in (root.edges.map { generateNode(from: data, for: $0, parentNode: root) }) {
            ret.append(contentsOf: allNodes(from: childNode, in: data))
        }
        return ret
    }
    
    private func generateNode(from data: Data, for edge: ExportInfoNodeEdge?, parentNode: ExportInfoNode?) -> ExportInfoNode {
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
        
        return ExportInfoNode(startOffsetInMacho: self.data.startIndex + startOffset,
                              accumulatedString: accumulatedString,
                              terminalSize: terminalSizeLEB,
                              flags: retFlags,
                              leb128Array: leb128Array,
                              reExportedSymbolName: reExportedSymbolName,
                              edgesCount: edgesCountLEB,
                              edges: edges)
    }
}
