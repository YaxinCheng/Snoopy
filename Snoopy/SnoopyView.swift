//
//  SnoopyView.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import AVKit
import Foundation
import SpriteKit
import SwiftUI

struct SnoopyView: View {
    @StateObject private var viewModel = SnoopyViewModel()
    private var scene = SKScene()

    var body: some View {
        SpriteView(scene: scene)
            .onAppear {
                if viewModel.currentAnimation == nil {
                    viewModel.setup(scene: scene)
                    viewModel.startAnimation()
                }
            }
            .onReceive(viewModel.imageSequenceTimer) { _ in
                viewModel.updateImageSequence()
            }
            .onReceive(viewModel.videoDidFinishPlaying) { _ in
                viewModel.videoFinishedPlaying()
            }
            .onChange(of: viewModel.didFinishPlaying) {
                if viewModel.didFinishPlaying {
                    viewModel.moveToTheNextAnimation(scene: scene)
                }
            }
    }
}

#Preview {
    SnoopyView()
}
