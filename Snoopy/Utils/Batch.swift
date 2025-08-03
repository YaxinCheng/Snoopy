//
//  Batch.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-02.
//

import Foundation

enum Batch {
    static func syncLoad<R>(urls: Array<URL>, transform: @escaping (URL) -> R) -> [R] {
        let results = UnsafeMutablePointer<R>.allocate(capacity: urls.count)
        DispatchQueue.concurrentPerform(iterations: urls.count) { index in
            (results + index).initialize(to: transform(urls[index]))
        }
        return Array(UnsafeBufferPointer(start: results, count: urls.count))
    }
}
