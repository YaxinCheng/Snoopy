//
//  Once.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-05-05.
//

import Foundation

actor AsyncOnce {
    private var task: Task<Void, Error>?

    func execute(_ block: @Sendable @escaping () async throws -> Void) async throws {
        let executionTask: Task<Void, Error>
        if let existingTask = task {
            executionTask = existingTask
        } else {
            let newTask = Task {
                try await block()
            }
            task = newTask
            executionTask = newTask
        }
        do {
            try await executionTask.value
        } catch {
            task = nil
            throw error
        }
    }

    func execute(_ block: @Sendable @escaping () async -> Void) async {
        let executionTask: Task<Void, Error>
        if let existingTask = task {
            executionTask = existingTask
        } else {
            let newTask = Task<Void, Error> {
                await block()
            }
            task = newTask
            executionTask = newTask
        }
        _ = await executionTask.result
    }
}
