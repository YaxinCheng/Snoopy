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

    var body: some View {
        animationView
            .onAppear {
                viewModel.startAnimation()
            }
    }
    
    @ViewBuilder
    var animationView: some View {
        switch viewModel.currentAnimation {
        case .video(let clip):
            VideoView(videos: viewModel.expandUrls(from: clip))
        case .imageSequence(let clip):
            ImageSequenceView(images: viewModel.expandUrls(from: clip))
        case nil:
            // TODO: set up background
            Color.black
        }
    }
}

#Preview {
    SnoopyView()
}
