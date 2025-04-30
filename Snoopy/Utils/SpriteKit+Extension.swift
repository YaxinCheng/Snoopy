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
}

extension SKNode {
    func center(in scene: SKScene) {
        position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
    }
}

extension SKSpriteNode {
    @discardableResult
    func fullscreen(in scene: SKScene) -> Self {
        self.size = scene.size
        center(in: scene)
        return self
    }
}
