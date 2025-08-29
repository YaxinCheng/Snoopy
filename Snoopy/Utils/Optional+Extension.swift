//
//  Optional+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-01.
//

import Foundation

func OptionalToArray<T>(_ value: [T]?) -> [T] {
    value ?? []
}

func OptionalToArray<T>(_ value: T?) -> [T] {
    guard let value = value else {
        return []
    }
    return [value]
}

extension Optional {
    func asyncMap<T>(_ transform: @escaping (Wrapped) async throws -> T) async rethrows -> T? {
        if let self {
            return try await transform(self)
        }
        return nil
    }
}
