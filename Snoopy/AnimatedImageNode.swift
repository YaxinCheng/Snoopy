//
//  AnimatedImageNode.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-19.
//

import Combine
import SpriteKit

class AnimatedImageNode: SKSpriteNode {
    private var resources: [URL]
    private var currentIndex: Int = 0

    init(contentsOf resources: [URL]) {
        assert(!resources.isEmpty, "Empty resources for AnimatedImageNode is not allowed")
        self.resources = resources
        let initialTexture = SKTexture(contentsOf: resources[0])
        let initialSize = initialTexture?.size()
        super.init(texture: initialTexture, color: .clear, size: initialSize ?? .zero)
    }
    
    func fullscreen(in scene: SKScene) -> Self {
        self.size = scene.size
        self.center(in: scene)
        return self
    }
    
    @MainActor
    @discardableResult
    func update() -> Bool {
        if currentIndex < resources.count {
            texture = SKTexture(contentsOf: resources[currentIndex])
            currentIndex += 1
            return currentIndex == resources.count - 1
        } else {
            return true
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        self.resources = []
        super.init(coder: aDecoder)
    }
    
    var isFinished: Bool {
        currentIndex >= resources.count - 1
    }
}
