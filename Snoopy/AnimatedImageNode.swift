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
    private let urls: [URL]
    private static let BATCH_SIZE = 5

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
        self.init(urls: resources, firstBatchOfTextures: Batch.syncLoad(urls: resources[..<Self.BATCH_SIZE], transform: SKTexture.mustCreateFrom(contentsOf:)))
    }

    static func asyncCreate(contentsOf resources: [URL]) async -> AnimatedImageNode {
        #if DEBUG
        guard !resources.isEmpty else {
            Log.fault("Empty resources for AnimatedImageNode is not allowed")
        }
        #endif
        Log.debug("AnimatedImageNode created with resources: [\(resources.lazy.map(\.lastPathComponent).joined(separator: ", "))]")
        return await Task.detached {
            let textures = await Batch.syncLoad(urls: resources[..<Self.BATCH_SIZE], transform: SKTexture.mustCreateFrom(contentsOf:))
            return await MainActor.run {
                AnimatedImageNode(urls: resources, firstBatchOfTextures: textures)
            }
        }.value
    }

    private init(urls: [URL], firstBatchOfTextures: [SKTexture]) {
        self.urls = urls
        textures = firstBatchOfTextures
        let initialTexture = firstBatchOfTextures.first
        let initialSize = initialTexture?.size()
        super.init(texture: initialTexture, color: .clear, size: initialSize ?? .zero)
        texture = initialTexture
    }

    @MainActor
    func play(timePerFrame interval: TimeInterval) async {
        var actions = [SKAction]()
        actions.reserveCapacity(urls.count)
        for index in 0 ..< urls.count {
            let textureIndex = index % Self.BATCH_SIZE

            let setTextureAction = SKAction.run { [weak self] in
                self?.texture = self?.textures[textureIndex]
            }

            let preloadNextTextureAction = SKAction.run { [weak self] in
                let cacheIndex = index + Self.BATCH_SIZE
                guard cacheIndex < self?.urls.count ?? -1 else { return }
                Task.detached { [weak self] in
                    guard let url = self?.urls[cacheIndex], let texture = SKTexture(contentsOf: url) else { return }
                    await MainActor.run { [weak self] in
                        self?.textures[textureIndex] = texture
                    }
                }
            }
            
            let waitAction = SKAction.wait(forDuration: interval)
            
            actions.append(SKAction.group([setTextureAction, preloadNextTextureAction, waitAction]))
        }
        await run(SKAction.sequence(actions))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        urls = []
        super.init(coder: aDecoder)
    }
}
