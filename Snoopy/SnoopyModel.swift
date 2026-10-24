//
//  SnoopyModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-29.
//

import Cocoa

private let BACKGROUND_COLOURS: [NSColor] = [
    NSColor(r: 136, g: 189, b: 242),
    NSColor(r: 212, g: 222, b: 149),
    NSColor(r: 227, g: 83, b: 54),
    .systemMint.blended(withFraction: 0.5, of: .white)!,
    .systemYellow.blended(withFraction: 0.5, of: .white)!,
    .systemIndigo.blended(withFraction: 0.5, of: .white)!,
    .systemOrange.blended(withFraction: 0.3, of: .white)!,
    .systemGreen.blended(withFraction: 0.5, of: .white)!
]

struct SnoopyModel {
    private static let animations: AnimationCollection = {
        let resourceFiles = Bundle.this
            .urls(forResourcesWithExtension: nil, subdirectory: "Animations") ?? []
        Log.debug("loaded \(resourceFiles.count) resource files")
        return AnimationCollection.from(files: resourceFiles)
    }()
    
    var currentAnimation: Animation? {
        willSet {
            Log.debug("finished animation: \(currentAnimation?.name ?? "nil"), next animation: \(newValue?.name ?? "nil")")
            if let newValue, newValue.isImageSequence {
                decoration = if Int.random(in: 0 ... 9) >= 9 { // Only 10% of the time that we should have a decoration
                    SnoopyModel.animations.decorations.randomElement()
                } else {
                    nil
                }
            } else {
                decoration = nil
            }
        }
    }
    
    private(set) var currentMask: Mask?
    private(set) var currentTransition: Clip<URL>?
    private(set) var backgroundColor: NSColor = BACKGROUND_COLOURS.randomElement()!
    private(set) var snoopyHouse: URL
    private(set) var decoration: Animation?
    private(set) var specialConnection: Clip<ImageSequence>?
    
    init() {
        snoopyHouse = SnoopyModel.animations.snoopyHouses.randomElement()!
    }
    
    var background: URL? {
        SnoopyModel.animations.background
    }
    
    enum NextAnimationKind {
        case normal
        case dream
    }
    
    mutating func startRandomDream() {
        startAnimation(randomDream())
    }
    
    /// Move to the next animation
    mutating func moveToTheNextAnimation() -> NextAnimationKind {
        specialConnection = nil
        if let finishedAnimation = currentAnimation {
            if NameUtil.isDream(finishedAnimation.name) {
                startAnimation(wakeAnimation())
            } else if NameUtil.isRoofPose(finishedAnimation.name), !finishedAnimation.designated {
                startAnimation(randomDream())
                let shouldStartSpecialConnection = Int.random(in: 0 ... 9) >= 9 // 10% of chance
                if shouldStartSpecialConnection {
                    startSpecialConnection()
                }
                return .dream
            } else if let nextAnimation = nextAnimationOnJumpGraph(source: finishedAnimation) {
                startAnimation(nextAnimation)
            } else {
                startAnimation(randomAnimation())
            }
        }
        return .normal
    }
    
    private mutating func startAnimation(_ animation: Animation) {
        Log.info("start animation: \(animation.name)")
        let isFirstAnimation = currentAnimation == nil
        currentAnimation = animation
        let needsMask = NameUtil.isDream(animation.name)
        if needsMask {
            (currentTransition, currentMask) = isFirstAnimation ? SnoopyModel.animations.outroTransitionAndMask() : SnoopyModel.animations.randomTransitionAndMask()
        } else {
            currentMask = nil
            currentTransition = nil
        }
    }

    private mutating func startSpecialConnection() {
        specialConnection = SnoopyModel.animations.specialConnections.randomElement()!.unwrapToImageSequence()
        currentTransition = SnoopyModel.animations.randomNonDreamyTransition()
        currentMask = SnoopyModel.animations.randomMask()
    }
    
    private func randomAnimation() -> Animation {
        let animation = SnoopyModel.animations.jumpGraph.keys.randomElement()!
        Log.info("start random animation: \(animation.name)")
        return animation
    }

    private func randomDream() -> Animation {
        let animation = SnoopyModel.animations.dreams.randomElement()!
        Log.info("start random dream: \(animation.name)")
        return animation
    }
    
    private func wakeAnimation() -> Animation {
        let animation = SnoopyModel.animations.wakeAnimations.randomElement()!
        Log.info("start wake animation: \(animation)")
        return animation
    }
    
    private func nextAnimationOnJumpGraph(source: Animation) -> Animation? {
        let animation = SnoopyModel.animations.jumpGraph[source]?.randomElement()
        Log.info("next animation on jump graph: \"\(source.name)\" => \"\(animation?.name ?? "nil")\"")
        return animation
    }
}
