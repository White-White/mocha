//
//  AsyncLoader.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/31.
//

import Foundation

class AsyncLoader<T> {
    private let lockForLoading = NSLock()
    private var hasPreLoaded = false
    private let queue: DispatchQueue = DispatchQueue.global()
    private var _loaded: T?
    
    var assertLoaded: T {
        return loaded!
    }
    
    var loaded: T? {
        let ret: T?
        self.lockForLoading.lock()
        ret = _loaded
        self.lockForLoading.unlock()
        return ret
    }
    
    func load(_ callBack: @escaping () -> T) {
        queue.async {
            self.lockForLoading.lock()
            guard !self.hasPreLoaded else {
                self.lockForLoading.unlock()
                return
            }
            
            self._loaded = callBack()
            
            self.hasPreLoaded = true
            self.lockForLoading.unlock()
        }
    }
}
