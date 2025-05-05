//
//  SnoopyModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-29.
//

import Foundation

struct SnoopyModel {
    private let animations: AnimationCollection = {
        let resourceFiles = Bundle(for: SnoopyScene.self)
            .urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
        return AnimationCollection.from(files: resourceFiles)
    }()
    
    var currentAnimation: Animation? = nil {
        willSet {
            let needsMask = currentAnimation == nil || (newValue.map(\.name).map(ParsedFileName.isDream) ?? false)
            if needsMask {
                currentMask = animations.masks.randomElement()
                currentTransition = animations.dreamTransitions.randomElement()?.unwrapToVideo()
            } else {
                currentMask = nil
                currentTransition = nil
            }
        }
    }
    
    private(set) var currentMask: Mask?
    private(set) var currentTransition: Clip<URL>?
    
    var background: URL? {
        animations.background
    }
    
    var specialImages: [URL] {
        animations.specialImages
    }
    
    var decorations: [Animation] {
        animations.decorations
    }

    mutating func startRandomAnimation() {
        startAnimation(animations.jumpGraph.keys.randomElement()!)
    }

    mutating func startRandomDream() {
        startAnimation(animations.dreams.randomElement()!)
    }
    
    mutating func startRph() {
        startAnimation(animations.rph.randomElement()!)
    }
    
    mutating func startAnimation(_ animation: Animation) {
        currentAnimation = animation
    }

    func nextAnimationOnJumpGraph(source: Animation) -> Animation? {
        animations.jumpGraph[source]?.randomElement()
    }
    
    func isAnimationRph(_ animation: Animation) -> Bool {
        animations.rph.contains(animation)
    }
}
