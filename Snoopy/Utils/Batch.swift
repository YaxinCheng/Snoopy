//
//  Batch.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-02.
//

import Foundation

enum Batch {
    static func syncLoad<R>(urls: Array<URL>, transform: @escaping (URL) -> R) -> [R] {
        Array(unsafeUninitializedCapacity: urls.count) { buffer, initializedCount in
            DispatchQueue.concurrentPerform(iterations: urls.count) { index in
                (buffer.baseAddress! + index).initialize(to: transform(urls[index]))
            }
            initializedCount = urls.count
        }
    }
    
    static func asyncLoad<R>(urls: Array<URL>, transform: @escaping (URL)->R, completion: @escaping ([R])->Void) {
        Task.detached {
            completion(syncLoad(urls: urls, transform: transform))
        }
    }
}
