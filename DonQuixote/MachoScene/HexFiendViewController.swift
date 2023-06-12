//
//  HexFiendViewController.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/9.
//

import SwiftUI
import AppKit

public class HexFiendViewController: NSViewController {
    
    static let MouseDownNoti: Notification.Name = Notification.Name(rawValue: "DonQuiDidMouseDownOnHex")
    static let MouseDownNotiCharIndexKey: String = "DonQuiDidMouseDownOnHex_Index"
    
    static let bytesPerLine = 16
    let data: Data
    let hfController: HFController
    let layoutRep: HFLayoutRepresenter
    
    public override func loadView() {
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
        self.hfController.setController(self)
    }
    
    var selectedDataRange: Range<UInt64>? {
        didSet {
            if let selectedDataRange {
                self.hfController.selectedContentsRanges = [HexFiendViewController.hfRangeWrapper(from: selectedDataRange)]
            } else {
                self.hfController.selectedContentsRanges = [HFRangeWrapper.withRange(HFRange(location: 0, length: 0))]
            }
            self.scrollIfNeeded()
        }
    }
    var selectedComponentDataRange: Range<UInt64>? {
        didSet {
            if let selectedComponentDataRange {
                self.hfController.colorRanges = [HexFiendViewController.colorRange(from: selectedComponentDataRange)]
            }
            self.scrollIfNeeded()
        }
    }
    
    private func scrollIfNeeded() {
        if let selectedDataRange {
            self.scrollHexView(basedOn: selectedDataRange)
            return
        }
        
        if let selectedComponentDataRange {
            self.scrollHexView(basedOn: selectedComponentDataRange)
            return
        }
    }
    
    private func scrollHexView(basedOn selectedRange: Range<UInt64>) {
        self.hfController.scrollHexViewBased(on: NSMakeRange(Int(selectedRange.lowerBound), Int(selectedRange.upperBound - selectedRange.lowerBound)), bytesPerLine: UInt(HexFiendViewController.bytesPerLine))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    // exposed to Objective-C
    @objc
    func didClickCharacter(at index: UInt64) {
        let noti = Notification(name: HexFiendViewController.MouseDownNoti, object: self, userInfo: [HexFiendViewController.MouseDownNotiCharIndexKey: index])
        NotificationCenter.default.post(noti)
    }
}

struct ViewControllerRepresentable: NSViewControllerRepresentable {
    typealias NSViewControllerType = NSViewController
    let viewController: NSViewController
    func makeNSViewController(context: Context) -> NSViewController {
        return self.viewController
    }
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        
    }
}
