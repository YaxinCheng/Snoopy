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
    @Published var currentAnimationName: String?
    @Published var currentAnimation: Animation?

    func startAnimation() {
        guard let (name, animation) = randomAnimation() else { return }
        currentAnimationName = name
        currentAnimation = animation
    }

    private func randomAnimation() -> (String, Animation)? {
        guard
            let randomAnimationName = animations.keys.randomElement()
        else {
            return nil
        }
        return (randomAnimationName, animations[randomAnimationName]!.randomAnimation())
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
