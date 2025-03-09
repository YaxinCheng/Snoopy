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
    @State private var didFinishPlaying = false

    var body: some View {
        animationView
            .onAppear {
                viewModel.startAnimation()
            }
            .onChange(of: didFinishPlaying) {
                viewModel.moveToTheNextAnimation()
            }
    }

    @ViewBuilder
    var animationView: some View {
        switch viewModel.currentAnimation {
        case .video(let clip):
            VideoView(videos: viewModel.expandUrls(from: clip), didFinishPlaying: $didFinishPlaying)
        case .imageSequence(let clip):
            ImageSequenceView(images: viewModel.expandUrls(from: clip), didFinishBinding: $didFinishPlaying)
        case nil:
            // TODO: set up background
            Color.black
        }
    }
}

#Preview {
    SnoopyView()
}
