//
//  DocumentView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import SwiftUI

protocol DocumentView: View {
    associatedtype Content: View
    associatedtype D: File
    init(_ d: D)
    static func windowBuilder(_ location: Binding<FileLocation?>) -> Content
}

extension DocumentView {
    static func windowBuilder(_ location: Binding<FileLocation?>) -> some View {
        DocumentWindow<Self>(location.wrappedValue)
    }
}
