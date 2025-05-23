//
//  SnoopyViewModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import SwiftUI

@MainActor
final class SnoopyViewModel: ObservableObject {
    @Published private(set) var model = SnoopyModel()

    func setup(scene: SnoopyScene) {
        if model.currentAnimation == nil {
            model.startRandomDream()
        }
        scene.setup(animation: model.currentAnimation!, background: model.background, snoopyHouses: model.specialImages, mask: model.currentMask, transition: model.currentTransition, decorations: model.decorations)
    }

    func moveToTheNextAnimation(scene: SnoopyScene) {
        if let finishedAnimation = model.currentAnimation {
            if let nextAnimation = model.nextAnimationOnJumpGraph(source: finishedAnimation) {
                if model.isAnimationRph(nextAnimation) {
                    model.startRandomDream()
                } else {
                    model.startAnimation(nextAnimation)
                }
            } else if ParsedFileName.isDream(finishedAnimation.name) {
                model.startRph()
            } else {
                model.startRandomAnimation()
            }
        }
        setup(scene: scene)
    }
}
