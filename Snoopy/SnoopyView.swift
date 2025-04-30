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
            .onAppear {
                viewModel.setup(scene: scene)
            }
            .onReceive(scene.didFinishPlaying) { _ in
                viewModel.moveToTheNextAnimation(scene: scene)
            }
    }
}

#Preview {
    SnoopyView()
}
