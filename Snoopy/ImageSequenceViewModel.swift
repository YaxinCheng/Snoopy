//
//  ImageSequenceViewModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import Combine
import SpriteKit
import SwiftUI

class ImageSequenceViewModel: ObservableObject {
    private let images: [URL]
    private var timer: AnyCancellable?
    @Published private(set) var index = 0
    private static let timerInterval: TimeInterval = 0.06
    private(set) var scene: SKScene
    private var node: SKSpriteNode
    @Published private(set) var hasFinishedPlaying: Bool = false
    
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
    
    func play() {
        timer = Timer.publish(every: Self.timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if (self?.index ?? 0) + 1 >= (self?.images.count ?? 0) {
                    self?.timer?.cancel()
                    self?.hasFinishedPlaying = true
                } else {
                    self?.index += 1
                }
            }
    }
    
    @MainActor
    func update() {
        node.texture = texture
    }
    
    func stop() {
        timer?.cancel()
    }
}
