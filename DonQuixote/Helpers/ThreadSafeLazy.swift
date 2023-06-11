//
//  ThreadSafeLazy.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import Foundation

typealias ThreadSafeLazyInitBlock<T> = () -> T

class ThreadSafeLazy<T> {
    
    private var rwLock = pthread_rwlock_t()
    private let block: ThreadSafeLazyInitBlock<T>
    
    private var cachedValue: T?
    var value: T {
        var ret: T
        pthread_rwlock_rdlock(&self.rwLock)
        if let cachedValue {
            ret = cachedValue
        } else {
            ret = self.block()
            cachedValue = ret
        }
        return ret
    }
    
    init(_ block: @escaping ThreadSafeLazyInitBlock<T>) {
        self.block = block
        pthread_rwlock_init(&self.rwLock, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&self.rwLock)
    }
    
}
