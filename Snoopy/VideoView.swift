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

    init(videos: [URL]) {
        _viewModel = StateObject(wrappedValue: VideoViewModel(videos: videos))
    }

    var body: some View {
        SpriteView(scene: viewModel.scene)
            .onAppear {
                viewModel.play()
            }
            .onDisappear {
                viewModel.stop()
            }
            .onChange(of: viewModel.hasFinishedPlaying) {
                print("finished playing video")
            }
    }
}

#Preview {
    let animations = AnimationCollection.from(files: Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])

    VideoView(videos: animations["AP021"]!.urls)
}
