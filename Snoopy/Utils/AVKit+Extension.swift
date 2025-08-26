//
//  AVKit+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-27.
//

import AVKit

fileprivate final class KVOWrapper: @unchecked Sendable {
    var observation: NSKeyValueObservation?
}

extension AVPlayerItem {
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

    func waitUntil(item: AVPlayerItem, forTime time: CMTime, timeout: TimeInterval) async {
        await waitUntil(item: item, forTimes: [NSValue(time: time)], timeout: timeout)
    }

    /// waitUntil does nothing but wait for the player reaches the given time.
    /// Once the time is reached, it hands the control back to the process.
    private func waitUntil(item: AVPlayerItem, forTimes times: [NSValue], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            let observer = BoundaryTimeObserver()
            let continuation = ResumeManager(continuation: continuation)
            let timeoutTask = Task { [weak self] in
                await self?.waitForItem(item)
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await continuation.resume()
                observer.remove(from: self)
            }

            observer.observer = self.addBoundaryTimeObserver(forTimes: times, queue: .global()) { [weak self] in
                timeoutTask.cancel()
                Task {
                    await continuation.resume()
                    observer.remove(from: self)
                }
            }
        }
    }
    
    private func waitForItem(_ item: AVPlayerItem) async {
        await withCheckedContinuation { continuation in
            let wrapper = KVOWrapper()
            wrapper.observation = self.observe(\.currentItem, options: [.initial, .new]) { player, _ in
                if player.currentItem === item {
                    wrapper.observation?.invalidate()
                    continuation.resume()
                }
            }
        }
    }
}
