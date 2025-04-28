//
//  AVKit+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-27.
//

import AVKit

extension AVPlayerItem {
    func waitForItemReady(action: @escaping (AVPlayerItem)->Void) -> NSKeyValueObservation {
        self.observe(\.status, options: [.initial, .new]) { item, _ in
            guard item.status == .readyToPlay else { return }
            action(item)
        }
    }
}
