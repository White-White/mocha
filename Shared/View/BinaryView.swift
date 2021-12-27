//
//  DataView.swift
//  mocha
//
//  Created by white on 2021/6/29.
//

import SwiftUI
import Foundation

class BinaryViewHelper: ObservableObject {
    var visiableBinaryLineIndex: Set<Int> = []
    @Published var selectedTranslation: LazyTranslation
    init(_ t: LazyTranslation) { _selectedTranslation = Published(initialValue: t) }
}

struct BinaryView: View {
    
    @Binding var store: BinaryTranslationStore
    @Binding var digitsCount: Int
    @ObservedObject var helper: BinaryViewHelper
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 4) {
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: true)  {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<store.numberOfBinaryLines, id: \.self) { index in
                                HStack(alignment: .center, spacing: 0) {
                                    Text(store.binaryLine(at: index).indexTagString(with: digitsCount))
                                        .background(Color(.sRGB, red: 228/255, green: 228/255, blue: 228/255, opacity: 1))
                                        .font(.system(size: 12).monospaced())
                                        .foregroundColor(.secondary)
                                        .fixedSize()
                                    Text(store.binaryLine(at: index).dataHexString(selectedRange: helper.selectedTranslation.range))
                                        .background((index % 2 == 0) ? Color(red: 244.0/255, green: 245.0/255, blue: 245.0/255) : .white)
                                        .font(.system(size: 12).monospaced())
                                        .textSelection(.enabled)
                                        .fixedSize()
                                        .padding(.leading, 4)
                                }
                                .onAppear { helper.visiableBinaryLineIndex.insert(index) }
                                .onDisappear { helper.visiableBinaryLineIndex.remove(index) }
                            }
                        }
                        .padding(4)
                    }
                    .onReceive(helper.$selectedTranslation) { translation in
                        if let index = store.binaryLineIndex(for: translation), !helper.visiableBinaryLineIndex.contains(index) {
                            withAnimation { scrollProxy.scrollTo(index, anchor: .center) }
                        }
                    }
                    .background(.white)
                    .border(.separator, width: 1)
                    .padding(.bottom, 4)
                    .fixedSize(horizontal: true, vertical: false)
                }
                
                
                ScrollView(.vertical, showsIndicators: true)  {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<store.numberOfTranslations, id: \.self) { index in
                            ExplanationView(store.translation(at: index), selectedID: helper.selectedTranslation.id)
                                .onTapGesture {
                                self.helper.selectedTranslation = store.translation(at: index)
                            }
                        }
                    }
                    .padding(4)
                }
                .background(.white)
                .border(.separator, width: 1)
            }
        }
    }
    
    init(_ store: Binding<BinaryTranslationStore>, digitsCount: Binding<Int>) {
        _store = store
        _digitsCount = digitsCount
        self.helper = BinaryViewHelper(store.wrappedValue.translation(at: 0))
    }
}

struct ExplanationView: View {
    
    let readable: Readable
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if let dividerName = readable.dividerName {
                Divider()
                    .padding(.top, 2)
                Text(dividerName)
                    .font(.system(size: 14).bold())
                    .padding(.leading, 4)
                    .padding(.trailing, 4)
                Divider()
                    .padding(.bottom, 2)
            }
            VStack(alignment: .leading, spacing: 0) {
                if let description = readable.description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.top, 4)
                        .padding(.leading, 4)
                        .padding(.trailing, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(readable.explanation)
                    .foregroundColor(isSelected ? .white : .black)
                    .font(.system(size: 14))
                    .padding(.leading, 4)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 4).fill(isSelected ? Theme.selected : .white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 2)
    }
    
    init(_ translation: LazyTranslation, selectedID: UUID?) {
        readable = translation.readableGenerator()
        isSelected = translation.id == selectedID
    }
}

