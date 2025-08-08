//
//  SpriteKit+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-16.
//

import Foundation
import SpriteKit

extension SKTexture {
    convenience init?(contentsOf imageURL: URL) {
        guard let image = NSImage(contentsOf: imageURL) else {
            return nil
        }
        self.init(image: image)
    }

    convenience init?(imageData: Data) {
        guard let image = NSImage(data: imageData) else {
            return nil
        }
        self.init(image: image)
    }
    
    static func mustCreateFrom(contentsOf imageURL: URL) -> SKTexture {
        SKTexture(contentsOf: imageURL)!
    }

    static func mustCreateFrom(imageData: Data) -> SKTexture {
        SKTexture(imageData: imageData)!
    }
}

protocol SKSizedNode: SKNode {
    var size: CGSize { get set }
    var position: CGPoint { get set }
}

extension SKSizedNode {
    @discardableResult
    func fullscreen(in scene: SKScene?) -> Self {
        guard let scene = scene else { return self }
        self.size = scene.size
        self.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        return self
    }
}

extension SKSpriteNode: SKSizedNode {}
extension SKVideoNode: SKSizedNode {}
