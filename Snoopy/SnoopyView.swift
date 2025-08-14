//
//  SnoopyView.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import SpriteKit
import SwiftUI

struct SnoopyView: View {
    @StateObject private var viewModel = SnoopyViewModel()
    private let scene = SnoopyScene()

    var body: some View {
        SpriteView(scene: scene)
            .task {
                await viewModel.setup(scene: scene)
            }
            .onReceive(scene.didFinishPlaying) {
                Task {
                    await viewModel.moveToTheNextAnimation(scene: scene)
                }
            }
    }
}

#Preview {
    SnoopyView()
}
