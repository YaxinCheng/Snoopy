//
//  AVKit+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-27.
//

import AVKit

extension AVPlayerItem {
    private final class KVOWrapper: @unchecked Sendable {
        var observation: NSKeyValueObservation?
    }
    
    func ready() async -> AVPlayerItem {
        await withCheckedContinuation { continuation in
            let wrapper = KVOWrapper()
            wrapper.observation = self.observe(\.status, options: [.initial, .new]) { item, _ in
                if item.status == .readyToPlay {
                    wrapper.observation?.invalidate()
                    continuation.resume(returning: item)
                }
            }
        }
    }
}

extension AVPlayer {
    private final class BoundaryTimeObserver: @unchecked Sendable {
        var observer: Any?
    }
    
    /// waitUntil does nothing but wait for the player reaches the given time.
    /// Once the time is reached, it hands the control back to the process.
    func waitUntil(forTimes times: [NSValue]) async {
        await withCheckedContinuation { continuation in
            let observer = BoundaryTimeObserver()
            observer.observer = self.addBoundaryTimeObserver(forTimes: times, queue: .global()) {
                if let observer = observer.observer {
                    self.removeTimeObserver(observer)
                }
                continuation.resume()
            }
        }
    }
}
