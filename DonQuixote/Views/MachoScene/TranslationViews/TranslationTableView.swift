//
//  NSTableViewWrapper.swift
//  DonQuixote
//
//  Created by white on 2025/6/20.
//

import Foundation
import SwiftUI

class TranslationTableViewCell: NSTableCellView {
    
    static let cellID = "transCellID"
    
    var translation: Translation? {
        didSet {
            self.updateCell()
        }
    }
    
    let humanReadableTF = NSTextField.labelStyledTF(font: .systemFont(ofSize: 14), textColor: .textColor)
    let definitionTF = NSTextField.labelStyledTF(font: .systemFont(ofSize: 12), textColor: .secondaryLabelColor)
    let extraHumanReadableTF = NSTextField.labelStyledTF(font: .systemFont(ofSize: 13), textColor: .textColor)
    let extraDefinitionTF = NSTextField.labelStyledTF(font: .systemFont(ofSize: 12), textColor: .secondaryLabelColor)
    let separator = NSBox()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        separator.boxType = .separator
        self.addSubview(separator)
        self.addSubview(humanReadableTF)
        self.addSubview(definitionTF)
        self.addSubview(extraHumanReadableTF)
        self.addSubview(extraDefinitionTF)
    }
    
    func updateCell() {
        
        if let humanReadable = translation?.humanReadable {
            self.humanReadableTF.isHidden = false
            self.humanReadableTF.stringValue = humanReadable
        } else {
            self.humanReadableTF.isHidden = true
        }
        if let definition = translation?.definition {
            self.definitionTF.isHidden = false
            self.definitionTF.stringValue = definition
        } else {
            self.definitionTF.isHidden = true
        }
        if let extraHumanReadable = translation?.extraHumanReadable {
            self.extraHumanReadableTF.isHidden = false
            self.extraHumanReadableTF.stringValue = extraHumanReadable
        } else {
            self.extraHumanReadableTF.isHidden = true
        }
        if let extraDefinition = translation?.extraDefinition {
            self.extraDefinitionTF.isHidden = false
            self.extraDefinitionTF.stringValue = extraDefinition
        } else {
            self.extraDefinitionTF.isHidden = true
        }
        self.needsLayout = true
    }
    
    override func layout() {
        super.layout()
        separator.frame = CGRectMake(0, 0, self.width, 1)
        
        self.humanReadableTF.sizeToFit()
        self.definitionTF.sizeToFit()
        self.extraHumanReadableTF.sizeToFit()
        self.extraDefinitionTF.sizeToFit()
        
        self.humanReadableTF.topLeftPoint = CGPoint(x: 0, y: self.height - 4)
        var lastView = humanReadableTF
        
        if !self.definitionTF.isHidden {
            self.definitionTF.topLeftPoint = CGPoint(x: lastView.x, y: lastView.y - 4)
            lastView = self.definitionTF
        }
        
        if !self.extraHumanReadableTF.isHidden {
            self.extraHumanReadableTF.topLeftPoint = CGPoint(x: lastView.x, y: lastView.y - 4)
            lastView = self.extraHumanReadableTF
        }
        
        if !self.extraDefinitionTF.isHidden {
            self.extraDefinitionTF.topLeftPoint = CGPoint(x: lastView.x, y: lastView.y - 4)
            lastView = self.extraDefinitionTF
        }
        
    }
    
}

class TranslationTableViewCoordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    let translationGroups: TranslationGroups
    
    init(translationGroups: TranslationGroups) {
        self.translationGroups = translationGroups
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.translationGroups.translationGroups.reduce(0) { $0 + $1.translations.count }
    }
    
    @MainActor
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let theCell: TranslationTableViewCell
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(TranslationTableViewCell.cellID), owner: nil) as? TranslationTableViewCell {
            theCell = cell
        } else {
            theCell = TranslationTableViewCell()
        }
        theCell.identifier = NSUserInterfaceItemIdentifier(TranslationTableViewCell.cellID)
        theCell.translation = self.translationAt(row: row)
        return theCell
    }
    
    func translationAt(row: Int) -> Translation {
        var row = row
        for translationGroup in translationGroups.translationGroups {
            if translationGroup.translations.count > row {
                return translationGroup.translations[row]
            } else {
                row -= translationGroup.translations.count
            }
        }
        fatalError()
    }
    
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 100
    }
    
}

struct TranslationTableView: NSViewRepresentable {
    
    typealias NSViewType = NSScrollView
    
    let translationGroups: TranslationGroups
    
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
    
    func makeCoordinator() -> TranslationTableViewCoordinator {
        return TranslationTableViewCoordinator(translationGroups: self.translationGroups)
    }
    
    
}
