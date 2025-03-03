//
//  ImageSequenceView.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import SpriteKit
import SwiftUI

struct ImageSequenceView: View {
    @StateObject private var viewModel: ImageSequenceViewModel

    init(images: [URL]) {
        _viewModel = StateObject(wrappedValue:
            ImageSequenceViewModel(images: images))
    }

    var body: some View {
        SpriteView(scene: viewModel.scene)
            .onAppear {
                viewModel.play()
            }
            .onChange(of: viewModel.index) {
                viewModel.update()
            }
            .onDisappear {
                viewModel.stop()
            }
            .onChange(of: viewModel.hasFinishedPlaying) {
                print("finished playing imageSeq")
            }
    }
}

#Preview {
    let animations = AnimationCollection.from(files: Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])

    ImageSequenceView(images: animations["SS001"]!.urls)
}
