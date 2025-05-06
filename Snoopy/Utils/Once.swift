//
//  Once.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-05-05.
//

import Foundation

final class Once {
    private var executed: Bool = false
    private let queue: DispatchQueue

    init(label: String) {
        queue = DispatchQueue(label: label)
    }

    func execute(_ block: () -> Void) {
        queue.sync { [weak self] in
            let executed = self?.executed ?? false
            if !executed {
                block()
                self?.executed = true
            }
        }
    }
}
