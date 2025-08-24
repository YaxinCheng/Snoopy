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

        func remove(from player: AVPlayer?) {
            if let observer = observer {
                player?.removeTimeObserver(observer)
                self.observer = nil
            }
        }
    }

    private actor ResumeManager {
        private var continuation: CheckedContinuation<Void, Never>?

        init(continuation: CheckedContinuation<Void, Never>?) {
            self.continuation = continuation
        }

        func resume() {
            continuation?.resume()
            continuation = nil
        }
    }

    func waitUntil(forTime time: CMTime, timeout: CMTime) async {
        await waitUntil(forTimes: [NSValue(time: time), NSValue(time: timeout)])
    }

    /// waitUntil does nothing but wait for the player reaches the given time.
    /// Once the time is reached, it hands the control back to the process.
    private func waitUntil(forTimes times: [NSValue]) async {
        await withCheckedContinuation { continuation in
            let observer = BoundaryTimeObserver()
            observer.observer = self.addBoundaryTimeObserver(forTimes: times, queue: .global()) { [weak self] in
                observer.remove(from: self)
                continuation.resume()
            }
        }
    }
}
