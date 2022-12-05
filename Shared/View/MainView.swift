//
//  MachoSelectionView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/8.
//

import SwiftUI
import UniformTypeIdentifiers

class OpenPanelDelegate: NSObject, NSOpenSavePanelDelegate {
    
    let unixArchiveType = UTType(filenameExtension: "a")
    let dylibType = UTType(filenameExtension: "dylib")
    
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
                if (contentType == .unixExecutable || contentType == self.unixArchiveType || contentType == self.dylibType) {
                    return true
                }
            }
            
            for knownMagic in [FatBinary.magic, MachoMetaData.magic32, MachoMetaData.magic64, UnixArchive.magic] {
                if let inputStream = InputStream(url: url) {
                    inputStream.open()
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: knownMagic.count)
                    defer { buffer.deallocate(); inputStream.close() }
                    let read = inputStream.read(buffer, maxLength: knownMagic.count)
                    if read == knownMagic.count {
                        if ([UInt8](Data(bytes: buffer, count: knownMagic.count)) == knownMagic) {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
}

struct MachoSelectionView: View {
    
    struct SeletableMachoMetaData {
        let machoMetaData: MachoMetaData
        var selected: Bool = false
    }
    
    @State var seletableMachoMetaDatas: [SeletableMachoMetaData]
    @Binding var selectedMacho: Macho?
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                List {
                    ForEach($seletableMachoMetaDatas, id: \.machoMetaData.id) { $seletableMachoMetaData in
                        HStack(alignment: .center) {
                            Toggle("", isOn: $seletableMachoMetaData.selected)
                            VStack(alignment: .leading) {
                                Text(seletableMachoMetaData.machoMetaData.fileName)
                                    .font(.system(size: 14))
                                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                                Text("Arch: \(seletableMachoMetaData.machoMetaData.machoHeader.cpuType.name)")
                                    .font(.system(size: 12))
                                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                                Text("Size: \(seletableMachoMetaData.machoMetaData.machoFileSize.hex)")
                                    .font(.system(size: 12))
                                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))
                            }
                            .cornerRadius(4)
                        }
                        Divider()
                    }
                }
                .frame(maxWidth: 300, maxHeight: 500)
                Button {
                    self.selectedMacho = (seletableMachoMetaDatas.first { $0.selected })?.machoMetaData.macho
                } label: {
                    Text("Open")
                }
                .disabled(seletableMachoMetaDatas.first { $0.selected } == nil)
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                Spacer()
            }
            Spacer()
        }
    }
    
    init(_ machoMetaDatas: [MachoMetaData], selectedMacho: Binding<Macho?>) {
        self.seletableMachoMetaDatas = machoMetaDatas.map { SeletableMachoMetaData(machoMetaData: $0) }
        _selectedMacho = selectedMacho
    }
    
}

struct MainView: View {

    let openPanelDelegate = OpenPanelDelegate()
    
    @State var selectedMacho: Macho? = nil
    @State var selectedFileURL: URL? = nil
    @State var machoMetaDatas: [MachoMetaData]? = nil
    
    var body: some View {
        if let selectedMacho = selectedMacho {
            MachoView(selectedMacho)
                .navigationTitle(selectedMacho.machoFileName + " (" + selectedMacho.machoHeader.cpuType.name + ")")
        } else if let machoMetaDatas = machoMetaDatas {
            MachoSelectionView(machoMetaDatas, selectedMacho: $selectedMacho)
                .navigationTitle(self.selectedFileURL?.lastPathComponent ?? "Invalid File Name ⚠️")
        } else {
            VStack {
                Button {
                    let openPanel = NSOpenPanel()
                    openPanel.treatsFilePackagesAsDirectories = true
                    openPanel.allowsMultipleSelection = false
                    openPanel.canChooseDirectories = false
                    openPanel.canCreateDirectories = false
                    openPanel.canChooseFiles = true
                    openPanel.delegate = self.openPanelDelegate
                    openPanel.begin {
                        if $0 == .OK, let fileURL = openPanel.url {
                            self.selectedFileURL = fileURL
                            if let machoMetaDatas = (try? MochaDocument(fileURL: fileURL))?.machoMetaDatas {
                                if machoMetaDatas.count == 1 {
                                    self.selectedMacho = machoMetaDatas.first?.macho
                                } else {
                                    self.machoMetaDatas = machoMetaDatas
                                }
                            }
                        }
                    }
                } label: {
                    Label("Open File", systemImage: "doc")
                }
            }
            .frame(width: 1200, height: 600)
        }
    }
    
}
