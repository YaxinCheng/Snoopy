//
//  Once.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-05-05.
//

import Foundation

actor AsyncOnce {
    private var executed: Bool = false

    func execute(_ block: @Sendable () async throws -> Void) async rethrows {
        if !executed {
            Log.debug("AsyncOnce executed")
            executed = true
            try await block()
        }
    }
}
