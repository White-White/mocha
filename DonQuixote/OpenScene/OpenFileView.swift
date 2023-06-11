//
//  OpenFileView.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import SwiftUI
import AppKit

private class OpenPanelDelegate: NSObject, NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        return KnownFileType.knowsFile(with: url)
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
                    if $0 == .OK, let fileURL = openPanel.url, let fileType = KnownFileType(fileURL) {
                        openWindow(id: fileType.rawValue, value: fileURL)
                        dismiss()
                    }
                }
            } label: {
                Label("Open File", systemImage: "doc")
            }
        }
        .padding()
    }
}
