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
        
        if let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .contentTypeKey]) {
            if let isDirectory = resourceValues.isDirectory,
                isDirectory {
                return true
            }
            if let isRegularFile = resourceValues.isRegularFile,
                !isRegularFile {
                return false
            }
            if let contentType = resourceValues.contentType {
                return KnownFileType(contentType) != nil
            }
        }
        
        return false
    }
}

struct OpenFileView: View {
    
    @Environment(\.openWindow) private var openWindow
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
                    if $0 == .OK,
                        let fileURL = openPanel.url,
                        let resourceValues = try? fileURL.resourceValues(forKeys: [.contentTypeKey]),
                        let contentType = resourceValues.contentType,
                        let fileType = KnownFileType(contentType) {
                        openWindow(id: fileType.rawValue, value: fileURL)
                    }
                }
            } label: {
                Label("Open File", systemImage: "doc")
            }
        }
        .padding()
    }
}
