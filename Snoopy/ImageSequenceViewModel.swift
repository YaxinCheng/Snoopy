//
//  ImageSequenceViewModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import Combine
import SpriteKit
import SwiftUI

private let TIMER_INTERNVAL: TimeInterval = 0.06

class ImageSequenceViewModel: ObservableObject {
    private let images: [URL]
    private var index = 0
    let timer = Timer.publish(every: TIMER_INTERNVAL, on: .main, in: .common)
    private(set) var scene: SKScene
    private var node: SKSpriteNode
    private var timerObserver: AnyCancellable?

    var hasFinishedPlaying: Bool {
        index >= images.count
    }

    @MainActor
    init(images: [URL], index: Int = 0) {
        self.images = images
        self.index = index
        scene = SKScene()
        node = SKSpriteNode()
        node.size = scene.size
        node.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        node.texture = texture
        scene.addChild(node)
    }

    private var texture: SKTexture {
        SKTexture(imageNamed: images[index].path())
    }

    @MainActor
    func start() {
        timerObserver = AnyCancellable(timer.connect())
    }

    @MainActor
    func stop() {
        timerObserver?.cancel()
        timerObserver = nil
    }

    @MainActor
    func update() {
        index += 1
        if index < images.count {
            node.texture = texture
        } else {
            timerObserver?.cancel()
        }
    }
}
