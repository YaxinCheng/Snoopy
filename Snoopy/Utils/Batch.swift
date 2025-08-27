//
//  Batch.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-02.
//

import Foundation

enum Batch {
    static func syncLoad<R>(urls: ArraySlice<URL>, transform: @escaping @Sendable (URL) -> R) -> [R] {
        Array(unsafeUninitializedCapacity: urls.count) { buffer, initializedCount in
            let baseAddress = buffer.baseAddress!
            DispatchQueue.concurrentPerform(iterations: urls.count) { index in
                (baseAddress + index).initialize(to: transform(urls[index]))
            }
            initializedCount = urls.count
        }
    }

    static func asyncLoad<R: Sendable>(urls: ArraySlice<URL>, transform: @escaping @Sendable (URL) throws -> R) async rethrows -> [R] {
        try await withThrowingTaskGroup(of: (Int, R).self) { group -> [R] in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    try (index, transform(url))
                }
            }
            var buffer = [R?](repeating: nil, count: urls.count)
            for try await (index, transformed) in group {
                buffer[index] = transformed
            }
            return buffer.map { $0! }
        }
    }
}
