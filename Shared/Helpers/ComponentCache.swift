//
//  ComponentCache.swift
//  mocha (macOS)
//
//  Created by white on 2022/12/8.
//

import Foundation

class ComponentCache {
    
    class NumberKey: NSObject {
        let int: Int
        init(_ int: Int) {
            self.int = int
        }
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? NumberKey else {
                return false
            }
            return int == other.int
        }
    }
    
    private let memoryCache: NSCache<NumberKey, NSData>
    private let diskCache: FileHandle
    
    init(fileURL: URL, memoryCacheMB: Int = 128) throws {
        self.memoryCache = NSCache()
        self.memoryCache.totalCostLimit = 1024 * 1024 * memoryCacheMB
        self.diskCache = try FileHandle(forReadingFrom: fileURL)
    }
    
    func dataAt(index: Int) throws {
//        let blockSize = 1024
//        let blockIndex = index / blockSize
//        if let data = self.memoryCache.object(forKey: NumberKey(blockIndex)) {
//
//        } else {
//            try diskCache.seek(toOffset: UInt64(blockIndex * blockIndex))
//            diskCache.read
//        }
    }
    
}
