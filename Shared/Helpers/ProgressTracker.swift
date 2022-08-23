//
//  ProgressTracker.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/20.
//

import Foundation

protocol InitProgressDelegate: AnyObject {
    func progressDidUpdate(with updated: Float, done: Bool, shouldWithAnimation: Bool)
}

class InitProgress {
    
    weak var delegate: InitProgressDelegate?
    private(set) var progress: Float = 0
    private let timeCreated: Double = CACurrentMediaTime()
    
    func updateProgressForInitialize(with progress: Float) {
        self.update(progress / 2, done: false)
    }
    
    func updateProgressForInitialize(finishedItems: Int, total: Int) {
        self.update(Float(finishedItems) / Float(total) / 2, done: false)
    }
    
    func updateProgressForTranslationInitialize(finishedItems: Int, total: Int) {
        if finishedItems == total {
            self.update(1, done: true)
        } else {
            self.update((0.5 + Float(finishedItems) / Float(total) / 2), done: false)
        }
    }
    
    func finishProgress() {
        self.update(1, done: true, shouldWithAnimation: CACurrentMediaTime() - self.timeCreated > 0.5)
    }
    
    private func update(_ progress: Float, done: Bool, shouldWithAnimation: Bool = true) {
        guard progress - self.progress > 0.02 || done else { return }
        self.progress = progress
        DispatchQueue.main.async {
            self.delegate?.progressDidUpdate(with: self.progress, done: done, shouldWithAnimation: shouldWithAnimation)
        }
    }
}
