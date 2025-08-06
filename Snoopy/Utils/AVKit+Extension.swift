//
//  AVKit+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-27.
//

import AVKit

extension AVPlayerItem {
    func ready() async -> AVPlayerItem {
        await withCheckedContinuation { continuation in
            var observation: NSKeyValueObservation?
            observation = self.observe(\.status, options: [.initial, .new]) { item, _ in
                if item.status == .readyToPlay {
                    observation?.invalidate()
                    continuation.resume(returning: item)
                }
            }
        }
    }
}

extension AVPlayer {
    /// waitUntil does nothing but wait for the player reaches the given time.
    /// Once the time is reached, it hands the control back to the process.
    func waitUntil(forTimes times: [NSValue]) async {
        await withCheckedContinuation { continuation in
            var observer: Any?
            observer = self.addBoundaryTimeObserver(forTimes: times, queue: .global()) {
                if let observer = observer {
                    self.removeTimeObserver(observer)
                }
                continuation.resume()
            }
        }
    }
}
