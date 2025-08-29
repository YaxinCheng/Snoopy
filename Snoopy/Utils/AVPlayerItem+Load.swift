//
//  AVPlayerItem+Load.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-28.
//

import AVKit

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
}
