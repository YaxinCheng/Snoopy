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
    private(set) var videos: [URL]
    private(set) var scene: SKScene
    private let videoNode: SKVideoNode
    private let lastPlayerItem: AVPlayerItem?
    let observer: NotificationCenter.Publisher

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
        observer = NotificationCenter
            .default
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: lastPlayerItem)
    }

    @MainActor
    func start() {
        videoNode.play()
    }

    @MainActor
    func stop() {
        videoNode.pause()
    }
}
