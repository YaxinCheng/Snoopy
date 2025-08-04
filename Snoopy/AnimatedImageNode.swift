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

    init(contentsOf resources: [URL]) {
        #if DEBUG
        guard !resources.isEmpty else {
            Log.fault("Empty resources for AnimatedImageNode is not allowed")
        }
        #endif
        Log.debug("AnimatedImageNode created with resources: [\(resources.lazy.map(\.lastPathComponent).joined(separator: ", "))]")
        self.textures = Batch.syncLoad(urls: resources) { SKTexture(contentsOf: $0)! }
        let initialTexture = self.textures.first
        let initialSize = initialTexture?.size()
        super.init(texture: initialTexture, color: .clear, size: initialSize ?? .zero)
    }
    
    func reset(contentsOf resources: [URL]) -> Self {
        #if DEBUG
        guard !resources.isEmpty else {
            Log.fault("Empty resources for AnimatedImageNode is not allowed")
        }
        #endif
        Log.debug("AnimatedImageNode reset with resources: [\(resources.lazy.map(\.lastPathComponent).joined(separator: ", "))]")
        textures = Batch.syncLoad(urls: resources) { SKTexture(contentsOf: $0)! }
        texture = textures.first
        return self
    }
    
    @MainActor
    @discardableResult
    func play(timePerFrame interval: TimeInterval, completion: @escaping ()->Void) -> AnimatedImageNode {
        let animation = SKAction.animate(with: textures, timePerFrame: interval)
        self.run(animation, completion: completion)
        return self
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        self.textures = []
        super.init(coder: aDecoder)
    }
}
