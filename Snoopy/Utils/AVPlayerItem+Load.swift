//
//  AVPlayerItem+Load.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-28.
//

import AVKit
import Combine

extension AVPlayerItem {
    static func load(url: URL) async -> AVPlayerItem {
        let asset = AVURLAsset(url: url)
        do {
            _ = try await asset.load(.isPlayable)
            return AVPlayerItem(asset: asset)
        } catch {
            return AVPlayerItem(url: url)
        }
    }

    func ready() async {
        if status == .readyToPlay || status == .failed {
            return
        }
        await withCheckedContinuation { continuation in
            final class SubscriptionBox: @unchecked Sendable {
                var cancellable: AnyCancellable?
                var resumed = false
            }
            let box = SubscriptionBox()
            box.cancellable = self.publisher(for: \.status)
                .filter { $0 == .readyToPlay || $0 == .failed }
                .first()
                .sink { _ in
                    if !box.resumed {
                        box.resumed = true
                        continuation.resume()
                    }
                    box.cancellable = nil
                }
        }
    }
}
