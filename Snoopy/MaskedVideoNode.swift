//
//  MaskedVideoNode.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-19.
//

import SpriteKit
import AVKit

final class MaskedVideoNode: SKCropNode, SKSizedNode {
    private let videoNode: SKVideoNode
    
    init(videoNode: SKVideoNode) {
        self.videoNode = videoNode
        super.init()
        addChild(videoNode)
    }
    
    private override init() {
        videoNode = SKVideoNode()
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        videoNode = SKVideoNode()
        super.init(coder: aDecoder)
    }
    
    var size: CGSize {
        set {
            videoNode.size = newValue
        } get {
            videoNode.size
        }
    }
    
    func play() {
        videoNode.play()
    }
}
