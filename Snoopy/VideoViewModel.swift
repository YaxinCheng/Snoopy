//
//  VideoViewModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import AVKit
import SpriteKit
import SwiftUI

@MainActor
class VideoViewModel: ObservableObject {
    @Published private(set) var videos: [URL]
    private(set) var scene: SKScene
    private let videoNode: SKVideoNode

    init(videos: [URL]) {
        self.videos = videos
        scene = SKScene()

        let playerItems = videos.map { AVPlayerItem(url: $0) }
        let player = AVQueuePlayer(items: playerItems)
        videoNode = SKVideoNode(avPlayer: player)
        videoNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        videoNode.size = scene.size
        scene.addChild(videoNode)
    }
    
    func play() {
        videoNode.play()
    }
    
    func stop() {
        videoNode.pause()
    }
}
