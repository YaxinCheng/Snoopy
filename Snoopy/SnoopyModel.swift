//
//  SnoopyModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-29.
//

import Foundation

struct SnoopyModel {
    private let animations: AnimationCollection = {
        let resourceFiles = Bundle.this
            .urls(forResourcesWithExtension: nil, subdirectory: "Animations") ?? []
        Log.debug("loaded \(resourceFiles.count) resource files")
        return AnimationCollection.from(files: resourceFiles)
    }()
    
    var currentAnimation: Animation? = nil {
        willSet {
            Log.debug("current animation: \(currentAnimation?.name ?? "nil"), next animation: \(newValue?.name ?? "nil")")
            let needsMask = currentAnimation == nil || (newValue.map(\.name).map(ParsedFileName.isDream) ?? false)
            if needsMask {
                (currentTransition, currentMask) = animations.randomTransitionAndMask()
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
        Log.info("start random animation")
        currentAnimation = animations.jumpGraph.keys.randomElement()
    }

    mutating func startRandomDream() {
        Log.info("start random dream")
        currentAnimation = animations.dreams.randomElement()
    }
    
    mutating func startRph() {
        Log.info("start rph animation")
        currentAnimation = animations.rph.randomElement()
    }
    
    mutating func startAnimation(_ animation: Animation) {
        Log.info("start designated animation")
        currentAnimation = animation
    }

    func nextAnimationOnJumpGraph(source: Animation) -> Animation? {
        animations.jumpGraph[source]?.randomElement()
    }
    
    func isAnimationRph(_ animation: Animation) -> Bool {
        animations.rph.contains(animation)
    }
}
