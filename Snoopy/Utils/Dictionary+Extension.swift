//
//  Dictionary+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-13.
//

import Foundation

extension Dictionary {
    mutating func setDefault(_ defaultValue: Value, forKey key: Key) {
        setDefault(defaultValue, forKey: key) { _ in }
    }

    mutating func setDefault(_ defaultValue: Value, forKey key: Key, then do: (inout Value) -> Void) {
        if self[key] == nil {
            self[key] = defaultValue
        }
        `do`(&self[key]!)
    }
}
