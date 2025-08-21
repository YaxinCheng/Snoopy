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

    func setup(scene: SnoopyScene) async {
        if model.currentAnimation == nil {
            model.startRandomDream()
        }
        await scene.setup(animation: model.currentAnimation!, backgroundColor: model.backgroundColor, background: model.background, snoopyHouse: model.snoopyHouse, mask: model.currentMask, transition: model.currentTransition, decorations: model.decorations)
    }

    func moveToTheNextAnimation(scene: SnoopyScene) async {
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
        await setup(scene: scene)
    }
}
