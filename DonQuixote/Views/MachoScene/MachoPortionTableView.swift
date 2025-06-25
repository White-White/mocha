//
//  MachoPortionTableView.swift
//  DonQuixote
//
//  Created by white on 2025/6/23.
//

import Foundation
import SwiftUI

class MachoPortionTableRowView: NSTableRowView {
    
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle == .none {
            NSColor.white.setFill()
            NSColor.white.setStroke()
        } else {
            NSColor.selectedTextBackgroundColor.setFill()
            NSColor.selectedTextBackgroundColor.setStroke()
        }
        let bezier = NSBezierPath(rect: dirtyRect)
        bezier.fill()
        bezier.stroke()
    }
    
}

class MachoPortionTableViewCell: NSTableCellView {
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            switch backgroundStyle {
            case .emphasized:
                self.updateStyle(isSelected: true)
            default:
                self.updateStyle(isSelected: false)
            }
        }
    }
    
    var machoPortion: MachoPortion? {
        didSet {
            guard let machoPortion else { return }
            self.titleTF.stringValue = machoPortion.title
            self.rangeTF.stringValue = String(format: "Range: 0x%0X - 0x%0X", machoPortion.offsetInMacho, machoPortion.offsetInMacho + machoPortion.dataSize)
            self.sizeTF.stringValue = String(format: "Size: 0x%0X(%d) Bytes", machoPortion.dataSize, machoPortion.dataSize)
            self.needsLayout = true
        }
    }
    
    let titleTF: NSTextField = NSTextField.labelStyledTF(font: .boldSystemFont(ofSize: 12), textColor: .textColor)
    let rangeTF: NSTextField = NSTextField.labelStyledTF(font: .systemFont(ofSize: 11), textColor: .textColor)
    let sizeTF: NSTextField = NSTextField.labelStyledTF(font: .systemFont(ofSize: 11), textColor: .textColor)
    let separator = NSBox()
    static let cellID = "MachoPortionTableViewCell"
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        separator.boxType = .separator
        self.addSubview(separator)
        self.addSubview(titleTF)
        self.addSubview(rangeTF)
        self.addSubview(sizeTF)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        separator.frame = CGRectMake(0, 0, self.width, 1)
        
        self.titleTF.sizeToFit()
        self.rangeTF.sizeToFit()
        self.sizeTF.sizeToFit()
        
        self.titleTF.topLeftPoint = CGPoint(x: 0, y: self.height - 4)
        self.rangeTF.topLeftPoint = CGPoint(x: self.titleTF.x, y: self.titleTF.y - 2)
        self.sizeTF.topLeftPoint = CGPoint(x: self.rangeTF.x, y: self.rangeTF.y - 2)
    }
    
    func updateStyle(isSelected: Bool) {

        if isSelected {
            layer?.backgroundColor = NSColor.selectedTextBackgroundColor.cgColor
        } else {
            layer?.backgroundColor = NSColor.white.cgColor
        }
        
    }
    
}

class MachoPortionTableViewCoordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    let machoPortions: [MachoPortion]
    var onSelectMachoPortion: ((_ index: Int) -> Void)?
    
    init(machoPortions: [MachoPortion]) {
        self.machoPortions = machoPortions
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.machoPortions.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let theCell: MachoPortionTableViewCell
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(MachoPortionTableViewCell.cellID), owner: nil) as? MachoPortionTableViewCell {
            theCell = cell
        } else {
            theCell = MachoPortionTableViewCell()
        }
        theCell.machoPortion = self.machoPortions[row]
        return theCell
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return MachoPortionTableRowView()
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        self.onSelectMachoPortion?(row)
        return true
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 56
    }
    
}

struct MachoPortionTableView: NSViewRepresentable {
    
    typealias NSViewType = NSScrollView
    
    let coordinator: MachoPortionTableViewCoordinator
    
    init(machoPortions: [MachoPortion]) {
        self.coordinator = MachoPortionTableViewCoordinator(machoPortions: machoPortions)
    }
    
    func makeNSView(context: Context) -> NSViewType {
        let scrollView = NSScrollView()
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsetsZero
        
        let tableView = NSTableView()
        tableView.style = .plain
        tableView.headerView = nil
        scrollView.documentView = tableView
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SingleColumn"))
                column.title = "Items"
                tableView.addTableColumn(column)
        
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> MachoPortionTableViewCoordinator {
        return self.coordinator
    }
    
    static func widthNeeded(for allMachoPortions: [MachoPortion]) -> CGFloat {
        return allMachoPortions.reduce(0) { partialResult, component in
            let attriString = NSAttributedString(string: component.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        } + 16
    }
    
    func onSelectMachoPortion(_ callback: @escaping (_ index: Int) -> Void) -> some View {
        self.coordinator.onSelectMachoPortion = callback
        return self
    }
    
}
