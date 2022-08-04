//
//  ProgressTracker.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/20.
//

import Foundation

protocol InitProgressDelegate: AnyObject {
    func iniProgressUpdate(with updated: Float, done: Bool)
}

class InitProgress {
    
    weak var delegate: InitProgressDelegate?
    private(set) var progress: Float
    
    init(progress: Float = 0) {
        self.progress = progress
    }
    
    func updateInitializeProgress(_ progress: Float) {
        self.update(progress / 2)
    }
    
    func updateTranslationInitializeProgress(_ progress: Float) {
        self.update(0.5 + progress / 2)
    }
    
    private func update(_ progress: Float) {
        let shouldUpdate = progress - self.progress > 0.02 || progress == 1
        guard shouldUpdate else { return }
        self.progress = progress
        DispatchQueue.main.async {
            self.delegate?.iniProgressUpdate(with: self.progress, done: false)
        }
        if progress == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.delegate?.iniProgressUpdate(with: self.progress, done: true)
            }
        }
    }
}
