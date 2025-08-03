//
//  AnimatedImageNode.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-19.
//

import Combine
import SpriteKit

final class AnimatedImageNode: SKSpriteNode {
    private var textures: [SKTexture?] = []
    private var currentIndex: Int = 0
    
    static let clear = AnimatedImageNode()
    
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
        self.textures = Batch.syncLoad(urls: resources) { SKTexture(contentsOf: $0) }
        let initialTexture = self.textures.first?.flatMap { $0 }
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
        textures = Batch.syncLoad(urls: resources) { SKTexture(contentsOf: $0) }
        texture = textures.first?.flatMap { $0 }
        currentIndex = 0
        return self
    }
    
    /// update the AnimatedImageNode to the next image,
    /// and return true for finished, false for still have more.
    @MainActor
    @discardableResult
    func update() -> Bool {
        if currentIndex < textures.count {
            texture = textures[currentIndex]
            currentIndex += 1
            return currentIndex == textures.count - 1
        } else {
            return true
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        self.textures = []
        super.init(coder: aDecoder)
    }
}
