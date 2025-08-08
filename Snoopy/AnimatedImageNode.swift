//
//  AnimatedImageNode.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-19.
//

import Combine
import SpriteKit

final class AnimatedImageNode: SKSpriteNode {
    private var textures: [SKTexture] = []
    
    static let clear: AnimatedImageNode = .init()

    private init() {
        super.init(texture: nil, color: .clear, size: .zero)
    }

    convenience init(contentsOf resources: [URL]) {
        #if DEBUG
        guard !resources.isEmpty else {
            Log.fault("Empty resources for AnimatedImageNode is not allowed")
        }
        #endif
        Log.debug("AnimatedImageNode created with resources: [\(resources.lazy.map(\.lastPathComponent).joined(separator: ", "))]")
        self.init(textures: Batch.syncLoad(urls: resources, transform: SKTexture.mustCreateFrom(contentsOf:)))
    }
    
    init(textures: [SKTexture]) {
        #if DEBUG
        guard !textures.isEmpty else {
            Log.fault("Empty textures for AnimatedImageNode is not allowed")
        }
        #endif
        self.textures = textures
        let initialTexture = self.textures.first
        let initialSize = initialTexture?.size()
        super.init(texture: initialTexture, color: .clear, size: initialSize ?? .zero)
        texture = initialTexture
    }
    
    @discardableResult
    func reset(contentsOf resources: [URL]) -> Self {
        #if DEBUG
        guard !resources.isEmpty else {
            Log.fault("Empty resources for AnimatedImageNode is not allowed")
        }
        #endif
        Log.debug("AnimatedImageNode reset with resources: [\(resources.lazy.map(\.lastPathComponent).joined(separator: ", "))]")
        return reset(textures: Batch.syncLoad(urls: resources, transform: SKTexture.mustCreateFrom(contentsOf:)))
    }
    
    @discardableResult
    func reset(textures: [SKTexture]) -> Self {
        self.textures = textures
        texture = textures.first
        return self
    }
    
    @MainActor
    @discardableResult
    func play(timePerFrame interval: TimeInterval) async -> AnimatedImageNode {
        Log.info("AnimatedImageNode played with interval: \(interval)")
        let animation = SKAction.animate(with: textures, timePerFrame: interval)
        await run(animation)
        return self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
