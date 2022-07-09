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
            if (viewModel.line.offset..<(viewModel.line.offset + HexFiendView.BytesPerLines)).overlaps(selectedItemRange) {
                let highlightRangeLowerBound = max(selectedItemRange.lowerBound - viewModel.line.offset, 0)
                let highlightRangeUpperBound = min(selectedItemRange.upperBound - viewModel.line.offset, HexFiendView.BytesPerLines)
                viewModel.highlightedDataRange = highlightRangeLowerBound..<highlightRangeUpperBound
                
                highlightedLineViewModelIndexSet.insert(index)
                highlightedLineViewModels.append(viewModel)
            }
        }
        
        self.visiableHighlightedLineIndex = highlightedLineViewModelIndexSet.min()
    }
    
    static func hexadecimalLines(from machoComponent: MachoComponent, dataRange: Range<Int>) -> [HexadecimalLine] {
        let data = machoComponent.data
        let byteStartIndex = max(data.startIndex, dataRange.lowerBound) - data.startIndex
        let byteEndIndex = min(data.startIndex + data.count, dataRange.upperBound) - data.startIndex
        guard byteStartIndex < byteEndIndex else { return [] }
        let linesStartIndex = byteStartIndex / HexFiendView.BytesPerLines
        var linesEndIndex = byteEndIndex / HexFiendView.BytesPerLines
        if (byteEndIndex % HexFiendView.BytesPerLines != 0) { linesEndIndex += 1 }
        var lines: [HexadecimalLine] = []
        for lineIndex in linesStartIndex..<linesEndIndex {
            let line = HexadecimalLine(data: data.subSequence(from: lineIndex * HexFiendView.BytesPerLines,
                                                              maxCount: HexFiendView.BytesPerLines))
            lines.append(line)
        }
        return lines
    }

}
