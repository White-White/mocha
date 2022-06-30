//
//  PageControlView.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/30.
//

import SwiftUI

struct PageControlView: View {
    
    @ObservedObject var translationViewModel: TranslationViewModel
    
    var minPage: Int { TranslationViewModel.MinPage }
    var maxPage: Int { translationViewModel.maxPage }
    var lastPage: Int? { translationViewModel.lastPage }
    var currentPage: Int { translationViewModel.currentPage }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()
            Button(action: gotoLastPage) {
                Label("Last Page", systemImage: "arrow.left")
            }
            .disabled(currentPage == minPage)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
            Text("Page: \(currentPage + 1) / \(maxPage + 1)")
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
            Button(action: gotoNextPage) {
                Label("Next Page", systemImage: "arrow.right")
            }
            .disabled(currentPage == maxPage)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
    }
    
    func gotoNextPage() {
        translationViewModel.currentPage += 1
    }
    
    func gotoLastPage() {
        translationViewModel.currentPage -= 1
    }
    
}
