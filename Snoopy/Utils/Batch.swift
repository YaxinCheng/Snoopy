//
//  Batch.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-02.
//

import Foundation

enum Batch {
    static func syncLoad<R>(urls: [URL], transform: @escaping @Sendable (URL) -> R) -> [R] {
        Array(unsafeUninitializedCapacity: urls.count) { buffer, initializedCount in
            let baseAddress = buffer.baseAddress!
            DispatchQueue.concurrentPerform(iterations: urls.count) { index in
                (baseAddress + index).initialize(to: transform(urls[index]))
            }
            initializedCount = urls.count
        }
    }

    static func asyncLoad<R: Sendable>(urls: [URL], transform: @escaping @Sendable (URL) -> R) async -> [R] {
        await withTaskGroup(of: (Int, R).self) { group -> [R] in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    (index, transform(url))
                }
            }
            var buffer = [R](unsafeUninitializedCapacity: urls.count) { _, initializedCount in
                initializedCount = urls.count
            }
            for await (index, transformed) in group {
                buffer[index] = transformed
            }
            return buffer
        }
    }
}
