//
//  ProgressTracker.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/20.
//

import Foundation

class InitProgress: ObservableObject {
    
    @Published private(set) var progress: Float = 0
    @Published var isDone: Bool = false
    
    func updateProgressForInitialize(with progress: Float) {
        self.setProgress(progress / 2)
    }
    
    func updateProgressForInitialize(finishedItems: Int, total: Int) {
        self.updateProgressForInitialize(with: Float(finishedItems) / Float(total))
    }
    
    func updateProgressForTranslationInitialize(finishedItems: Int, total: Int) {
        self.setProgress((0.5 + Float(finishedItems) / Float(total) / 2))
    }
    
    func finishProgress() {
        DispatchQueue.main.async {
            self.setProgress(1)
            self.isDone = true
        }
    }
    
    func setProgress(_ progress: Float) {
        guard progress - self.progress > 0.02 || progress == 1 else { return }
        DispatchQueue.main.async {
            self.progress = progress
        }
    }
}
