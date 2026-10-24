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
        await scene.setup(animation: model.currentAnimation!, backgroundColor: model.backgroundColor, background: model.background, snoopyHouse: model.snoopyHouse, mask: model.currentMask, transition: model.currentTransition, decoration: model.decoration, specialConnection: model.specialConnection)
    }

    func moveToTheNextAnimation(scene: SnoopyScene) async {
        if case .dream = model.moveToTheNextAnimation() {
            scene.stopDecoration()
        }
        await setup(scene: scene)
    }
}
