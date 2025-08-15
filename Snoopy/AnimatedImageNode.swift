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

    private init() {
        Log.fault("Not implemented")
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

    @MainActor
    func play(timePerFrame interval: TimeInterval) async {
        let animation = SKAction.animate(with: textures, timePerFrame: interval)
        await run(animation)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
