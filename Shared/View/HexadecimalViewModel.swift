//
//  HexadecimalViewModel.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/30.
//

import Foundation

class HexadecimalViewModel: ObservableObject, TranslationViewModelObserver, Equatable {
    
    static func == (lhs: HexadecimalViewModel, rhs: HexadecimalViewModel) -> Bool {
        return lhs.machoComponent == rhs.machoComponent
    }
    
    static let LineBytesCount = 24
    
    let hexDigits: Int
    let machoComponent: MachoComponent
    
    var visiableDataRange: Range<Int>
    var highlightedLineViewModels: [HexadecimalLineViewModel] = []
    @Published var visiableHighlightedLineIndex: Int?
    @Published var linesViewModels: [HexadecimalLineViewModel]
    
    init(_ machoComponent: MachoComponent, translationViewModel:TranslationViewModel, hexDigits: Int) {
        self.hexDigits = hexDigits
        self.machoComponent = machoComponent
        self.visiableDataRange = translationViewModel.visiableDataRange
        
        let lines = HexadecimalViewModel.hexadecimalLines(from: machoComponent, dataRange: translationViewModel.visiableDataRange)
        self.linesViewModels = HexadecimalLineViewModel.viewModels(from: lines, hexDigits: hexDigits)
        
        if let selectedTranslationItem = translationViewModel.lastSelectedItemViewModel?.item {
            self.updateViewModels(with: selectedTranslationItem)
        }
        translationViewModel.observers.append(self)
    }
    
    func onChange(visiableDataRange: Range<Int>) {
        if self.visiableDataRange == visiableDataRange { return }
        let lines = HexadecimalViewModel.hexadecimalLines(from: machoComponent, dataRange: visiableDataRange)
        self.linesViewModels = HexadecimalLineViewModel.viewModels(from: lines, hexDigits: hexDigits)
    }
    
    func onChange(selectedItemViewModel: TranslationItemViewModel?, oldValue: TranslationItemViewModel?) {
        if let selectedTranslationItem = selectedItemViewModel?.item {
            self.updateViewModels(with: selectedTranslationItem)
        }
    }
    
    func updateViewModels(with selectedTranslationItem: TranslationItem) {
        highlightedLineViewModels.forEach { $0.highlightedDataRange = nil }
        highlightedLineViewModels.removeAll(keepingCapacity: true)
        guard let selectedItemRange = selectedTranslationItem.sourceDataRange else { return }
        
        var highlightedLineViewModelIndexSet = Set<Int>()
        
        for (index, viewModel) in linesViewModels.enumerated() {
            if (viewModel.line.offsetInMacho..<(viewModel.line.offsetInMacho + HexadecimalLine.LineBytesCount)).overlaps(selectedItemRange) {
                let highlightRangeLowerBound = max(selectedItemRange.lowerBound - viewModel.line.offsetInMacho, 0)
                let highlightRangeUpperBound = min(selectedItemRange.upperBound - viewModel.line.offsetInMacho, HexadecimalLine.LineBytesCount)
                viewModel.highlightedDataRange = highlightRangeLowerBound..<highlightRangeUpperBound
                
                highlightedLineViewModelIndexSet.insert(index)
                highlightedLineViewModels.append(viewModel)
            }
        }
        
        self.visiableHighlightedLineIndex = highlightedLineViewModelIndexSet.min()
    }
    
    static func hexadecimalLines(from machoComponent: MachoComponent, dataRange: Range<Int>) -> [HexadecimalLine] {
        let dataSlice = machoComponent.dataSlice
        let byteStartIndex = max(dataSlice.startOffset, dataRange.lowerBound) - dataSlice.startOffset
        let byteEndIndex = min(dataSlice.startOffset + dataSlice.count, dataRange.upperBound) - dataSlice.startOffset
        guard byteStartIndex < byteEndIndex else { return [] }
        let linesStartIndex = byteStartIndex / HexadecimalLine.LineBytesCount
        var linesEndIndex = byteEndIndex / HexadecimalLine.LineBytesCount
        if (byteEndIndex % HexadecimalLine.LineBytesCount != 0) { linesEndIndex += 1 }
        var lines: [HexadecimalLine] = []
        for lineIndex in linesStartIndex..<linesEndIndex {
            let line = HexadecimalLine(dataSlice: dataSlice.truncated(from: lineIndex * HexadecimalLine.LineBytesCount,
                                                                      maxLength: HexadecimalLine.LineBytesCount))
            lines.append(line)
        }
        return lines
    }

}
