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
    let inMemoryController: HFController
    let layoutRep: HFLayoutRepresenter
     
    override func loadView() {
        view = NSView(frame: .zero)
        let layoutView = layoutRep.view()
        layoutView.frame = view.bounds
        layoutView.autoresizingMask = [.width, .height]
        view.addSubview(layoutView)
    }
    
    init(data: Data) {
        self.data = data
        self.inMemoryController = HFController()
        self.inMemoryController.bytesPerColumn = 4
        self.inMemoryController.editable = false
        self.inMemoryController.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
        let byteSlice = HFSharedMemoryByteSlice(unsharedData: data)
        let byteArray = HFBTreeByteArray()
        byteArray.insertByteSlice(byteSlice, in: HFRangeMake(0, 0))
        inMemoryController.byteArray = byteArray
        
        self.layoutRep = HFLayoutRepresenter()
        let hexRep = HFHexTextRepresenter()
        let scrollRep = HFVerticalScrollerRepresenter()
        let lineCounting = HFLineCountingRepresenter()
        if let lineCountingView = lineCounting.view() as? HFLineCountingView {
            lineCountingView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            lineCountingView.lineNumberFormat = HFLineNumberFormat.hexadecimal
            lineCountingView.allowedTouchTypes = NSTouch.TouchTypeMask(rawValue: 0)
        }
        
        inMemoryController.addRepresenter(lineCounting)
        inMemoryController.addRepresenter(self.layoutRep)
        inMemoryController.addRepresenter(hexRep)
        inMemoryController.addRepresenter(scrollRep)
        
        self.layoutRep.addRepresenter(lineCounting)
        self.layoutRep.addRepresenter(hexRep)
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
    
    let preferredWidth: CGFloat = 580
    @Binding var selectedRange: Range<UInt64>
    @State var hexFiendViewController: HexFiendViewController
    
    var body: some View {
        ViewControllerRepresentable(viewController: self.hexFiendViewController)
            .frame(minWidth: self.preferredWidth)
            .onChange(of: selectedRange) { newValue in
                self.hexFiendViewController.inMemoryController.selectedContentsRanges = HexFiendView.hfRangeWrappers(from: newValue)
                
                // 24 bytes per line, as a result of fixed hex view width
                let targetLineIndex = Float80(newValue.lowerBound / 24)
                let visableLineRange = self.hexFiendViewController.inMemoryController.displayedLineRange
                if targetLineIndex < (visableLineRange.location + 5)
                    || targetLineIndex > (visableLineRange.location + visableLineRange.length - 5) {
                    let visableRangeMid = visableLineRange.location + visableLineRange.length / 2
                    let scrollingDistance = targetLineIndex - visableRangeMid
                    self.hexFiendViewController.inMemoryController.scroll(byLines: scrollingDistance)
                }
            }
    }
    
    init(data: Data, selectedRange: Binding<Range<UInt64>>) {
        _selectedRange = selectedRange
        _hexFiendViewController = State(initialValue: HexFiendViewController(data: data))
        self.hexFiendViewController.inMemoryController.selectedContentsRanges = HexFiendView.hfRangeWrappers(from: selectedRange.wrappedValue)
    }
    
    static func hfRangeWrappers(from range: Range<UInt64>) -> [Any] {
        guard range.upperBound > range.lowerBound else { return [] }
        let hfRange = HFRangeMake(range.lowerBound, range.upperBound - range.lowerBound)
        return [HFRangeWrapper.withRange(hfRange)]
    }
    
}
