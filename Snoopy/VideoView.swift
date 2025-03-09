//
//  VideoView.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import AVFoundation
import SpriteKit
import SwiftUI

struct VideoView: View {
    @StateObject private var viewModel: VideoViewModel
    private let didFinishPlaying: Binding<Bool>?

    init(videos: [URL], didFinishPlaying: Binding<Bool>? = nil) {
        _viewModel = StateObject(wrappedValue: VideoViewModel(videos: videos))
        self.didFinishPlaying = didFinishPlaying
    }

    var body: some View {
        SpriteView(scene: viewModel.scene)
            .onAppear {
                viewModel.start()
            }
            .onDisappear {
                viewModel.stop()
            }
            .onReceive(viewModel.observer) { _ in
                didFinishPlaying?.wrappedValue.toggle()
            }
    }
}

#Preview {
    let animations = AnimationCollection.from(files: Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])

    VideoView(videos: animations["AP021"]!.randomAnimation().urls)
}
