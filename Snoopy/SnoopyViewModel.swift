//
//  SnoopyViewModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import SwiftUI

private let LOOP_REPEAT_LIMIT: UInt = 3

final class SnoopyViewModel: ObservableObject {
    private static let resourceFiles =
        Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
    private let animations = AnimationCollection.from(files: resourceFiles)
    @Published var currentAnimation: Animation?

    func startAnimation() {
        currentAnimation = randomAnimation()
    }

    func moveToTheNextAnimation() {
        if let nextAnimationName = currentAnimation?.to {
            guard let nextAnimation = animations[nextAnimationName]?.randomAnimation() else {
                fatalError("Cannot find the next animation \"\(nextAnimationName)\"")
            }
            currentAnimation = nextAnimation
        } else {
            currentAnimation = randomAnimation()
        }
    }

    private func randomAnimation() -> Animation? {
        animations.values.randomElement()?.randomAnimation()
    }

    func expandUrls(from videoClip: Clip<URL>) -> [URL] {
        var result = [videoClip.intro!]
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(videoClip.loop).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(videoClip.outro))
        return result
    }

    func expandUrls(from imageSequenceClip: Clip<ImageSequence>) -> [URL] {
        var result = imageSequenceClip.intro?.urls ?? []
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(imageSequenceClip.loop?.urls).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(imageSequenceClip.outro?.urls))
        return result
    }
}
