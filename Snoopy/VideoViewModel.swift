//
//  VideoViewModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import AVKit
import Combine
import SpriteKit
import SwiftUI

@MainActor
class VideoViewModel: ObservableObject {
    @Published private(set) var videos: [URL]
    private(set) var scene: SKScene
    private let videoNode: SKVideoNode
    private let lastPlayerItem: AVPlayerItem?
    private var observer: AnyCancellable?
    @Published private(set) var hasFinishedPlaying = false

    init(videos: [URL]) {
        self.videos = videos
        scene = SKScene()

        let playerItems = videos.map { AVPlayerItem(url: $0) }
        lastPlayerItem = playerItems.last
        let player = AVQueuePlayer(items: playerItems)
        videoNode = SKVideoNode(avPlayer: player)
        videoNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        videoNode.size = scene.size
        scene.addChild(videoNode)
    }

    func play() {
        videoNode.play()
        observer = NotificationCenter
            .default
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: lastPlayerItem)
            .sink { [weak self] notification in
                self?.hasFinishedPlaying = (notification.object as? AVPlayerItem) == self?.lastPlayerItem
            }
    }

    func stop() {
        videoNode.pause()
        observer?.cancel()
    }
}
