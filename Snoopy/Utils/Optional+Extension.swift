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
