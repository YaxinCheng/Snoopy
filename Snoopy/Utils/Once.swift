//
//  Once.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-05-05.
//

import Foundation

struct Once {
    private var executed: Bool = false
    private var lock = os_unfair_lock_s()

    mutating func execute(_ block: () -> Void) {
        if executed { return }
        os_unfair_lock_lock(&lock)
        let hasExecuted = executed
        if !executed {
            executed = true
        }
        os_unfair_lock_unlock(&lock)
        if !hasExecuted {
            block()
        }
    }
}
