//
//  HexFiendViewController.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/9.
//

import SwiftUI
import AppKit

class HexFiendViewController: NSViewController {
    
    let data: Data
    let hfController: HFController
    let layoutRep: HFLayoutRepresenter
    
    override func loadView() {
        view = NSView(frame: .zero)
        let layoutView = layoutRep.view()
        layoutView.frame = view.bounds
        layoutView.autoresizingMask = [.width, .height]
        view.addSubview(layoutView)
    }
    
    init(data: Data) {
        HexFiendUtil.doSwizzleOnce()
        
        self.data = data
        self.hfController = HFController()
        self.hfController.bytesPerColumn = 1
        self.hfController.editable = false
        self.hfController.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        let byteSlice = HFSharedMemoryByteSlice(unsharedData: data)
        let byteArray = HFBTreeByteArray()
        byteArray.insertByteSlice(byteSlice, in: HFRangeMake(0, 0))
        hfController.byteArray = byteArray
        
        self.layoutRep = HFLayoutRepresenter()
        let hexRep = HFHexTextRepresenter()
        let scrollRep = HFVerticalScrollerRepresenter()
        let lineCounting = HFUntouchableLineCountingRepresenter()
        lineCounting.lineNumberFormat = HFLineNumberFormat.hexadecimal
        if let lineCountingView = lineCounting.view() as? HFLineCountingView {
            lineCountingView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        }
        let asciiRep = HFStringEncodingTextRepresenter()
        if let asciiView = asciiRep.view() as? HFRepresenterTextView {
            asciiView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        }
        
        hfController.addRepresenter(lineCounting)
        hfController.addRepresenter(self.layoutRep)
        hfController.addRepresenter(hexRep)
        hfController.addRepresenter(scrollRep)
        hfController.addRepresenter(asciiRep)
        
        self.layoutRep.addRepresenter(lineCounting)
        self.layoutRep.addRepresenter(hexRep)
        self.layoutRep.addRepresenter(asciiRep)
        self.layoutRep.addRepresenter(scrollRep)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct ViewControllerRepresentable: NSViewControllerRepresentable {
    typealias NSViewControllerType = NSViewController
    let viewController: NSViewController
    func makeNSViewController(context: Context) -> NSViewController {
        return self.viewController
    }
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        
    }
}

struct HexFiendView: View {
    
    static let bytesPerLine = 16
    
    @Binding var selectedRange: Range<UInt64>?
    @Binding var currentMachoComponentRange: Range<UInt64>
    @State var hexFiendViewController: HexFiendViewController
    
    var body: some View {
        HStack {
            ViewControllerRepresentable(viewController: self.hexFiendViewController)
                .frame(width: hexFiendViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendView.bytesPerLine)))
                .border(.separator, width: 1)
                .onChange(of: selectedRange) { newValue in
                    if let selectedRange = newValue {
                        self.hexFiendViewController.hfController.selectedContentsRanges = [HexFiendView.hfRangeWrapper(from: selectedRange)]
                        self.scrollHexView(basedOn: selectedRange)
                    }
                }
                .onChange(of: currentMachoComponentRange) { newValue in
                    self.hexFiendViewController.hfController.colorRanges = [HexFiendView.colorRange(from: newValue)]
                }
        }
    }
    
    init(data: Data, selectedRange: Binding<Range<UInt64>?>, currentMachoComponentRange: Binding<Range<UInt64>>) {
        _selectedRange = selectedRange
        _currentMachoComponentRange = currentMachoComponentRange
        _hexFiendViewController = State(initialValue: HexFiendViewController(data: data))
        if let selectedRange = selectedRange.wrappedValue {
            self.hexFiendViewController.hfController.selectedContentsRanges = [HexFiendView.hfRangeWrapper(from: selectedRange)]
            self.scrollHexView(basedOn: selectedRange)
        }
        self.hexFiendViewController.hfController.colorRanges = [HexFiendView.colorRange(from: currentMachoComponentRange.wrappedValue)]
    }
    
    func scrollHexView(basedOn selectedRange: Range<UInt64>) {
        let targetLineIndex = Float80(selectedRange.lowerBound / UInt64(HexFiendView.bytesPerLine))
        let visableLineRange = self.hexFiendViewController.hfController.displayedLineRange
        if targetLineIndex < (visableLineRange.location + 5)
            || targetLineIndex > (visableLineRange.location + visableLineRange.length - 5) {
            let visableRangeMid = visableLineRange.location + visableLineRange.length / 2
            let scrollingDistance = targetLineIndex - visableRangeMid
            self.hexFiendViewController.hfController.scroll(byLines: scrollingDistance)
        }
    }
    
    static func hfRangeWrapper(from range: Range<UInt64>) -> HFRangeWrapper {
        let hfRange = HFRangeMake(range.lowerBound, range.upperBound - range.lowerBound)
        return HFRangeWrapper.withRange(hfRange)
    }
    
    static func colorRange(from range: Range<UInt64>) -> HFColorRange {
        let colorRange = HFColorRange()
        colorRange.range = self.hfRangeWrapper(from: range)
        colorRange.color = NSColor.init(calibratedWhite: 212.0/255.0, alpha: 1)
        return colorRange
    }
    
}
