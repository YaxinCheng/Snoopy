//
//  VideoView.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import SwiftUI
import SpriteKit

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
    }
}

#Preview {
    let animations = AnimationCollection.from(files: Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])
    
    VideoView(videos: animations["AS005"]!.urls)
}
