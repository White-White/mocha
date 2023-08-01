//
//  OpenFileView.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

private class OpenPanelDelegate: NSObject, NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        var isDir: ObjCBool = false
        let _ = FileManager.default.fileExists(atPath: url.path(), isDirectory: &isDir)
        if isDir.boolValue { return true }
        return FileType.canOpen(url)
    }
}

struct OpenFileView: View {
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    private let openPanelDelegate = OpenPanelDelegate()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Button {
                let openPanel = NSOpenPanel()
                openPanel.treatsFilePackagesAsDirectories = true
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = false
                openPanel.canCreateDirectories = false
                openPanel.canChooseFiles = true
                openPanel.delegate = self.openPanelDelegate
                openPanel.begin {
                    if $0 == .OK, let fileURL = openPanel.url, let fileType = FileType.fileType(from: FileLocation(fileURL)) {
                        openWindow(id: fileType.rawValue, value: FileLocation(fileURL))
                        dismiss()
                    } else {
                        //TODO: 
                    }
                }
            } label: {
                Label("Open File", systemImage: "doc")
            }
        }
        .padding()
    }
}
