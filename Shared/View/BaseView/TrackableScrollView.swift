//
//  TrackableScrollView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/23.
//

import SwiftUI

struct TrackableScrollView<Content: View>: View {
    @ViewBuilder let content: (ScrollViewProxy) -> Content

    let onContentSizeChange: (CGSize) -> Void
    let onOffsetChange: (CGPoint) -> Void

    var body: some View {
        ScrollViewReader { reader in
            ScrollView() {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: geo.frame(in: .named("scrollView")).origin
                    )
                    .frame(width: 0, height: 0)
                }
                content(reader)
                    .background(
                        GeometryReader { geo -> Color in
                            DispatchQueue.main.async {
                                onContentSizeChange(geo.size)
                            }
                            return Color.clear
                        }
                    )
            }
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                onOffsetChange(offset)
            }
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    typealias Value = CGPoint
    static var defaultValue = CGPoint.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {}
}
