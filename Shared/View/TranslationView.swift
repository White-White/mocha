//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

struct TranslationView: View {
    
    @Binding var store: TranslationStore
    @Binding var selectedBinaryRange: Range<Int>?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true)  {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<store.dataSource.numberOfTranslationSections, id: \.self) { index in
                        TranslationSectionView(translationSection: store.dataSource.translationSection(at: index),
                                               selectedBinaryRange: $selectedBinaryRange)
                    }
                }
                .padding(4)
            }
            .background(.white)
            .border(.separator, width: 1)
            .onChange(of: store, perform: { newValue in
                scrollProxy.scrollTo(0, anchor: .top)
            })
            .frame(minWidth: 400)
        }
    }
}

struct TranslationSectionView: View {
    
    let translationSection: TransSection
    @Binding var selectedBinaryRange: Range<Int>?
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if let title = translationSection.title {
                Divider()
                    .padding(.top, 2)
                Text(title)
                    .font(.system(size: 14).bold())
                    .padding(.leading, 4)
                    .padding(.trailing, 4)
                Divider()
                    .padding(.bottom, 2)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(translationSection.terms, id: \.range) { term in
                    if let description = term.readable.description {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            .padding(.trailing, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(term.readable.explanation)
                        .foregroundColor(selectedBinaryRange == term.range ? .white : .black)
                        .font(.system(size: 14))
                        .padding(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .background {
                            RoundedRectangle(cornerRadius: 4).fill(selectedBinaryRange == term.range ? Theme.selected : .white)
                        }
                        .onTapGesture {
                            selectedBinaryRange = term.range
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 2)
    }
}

