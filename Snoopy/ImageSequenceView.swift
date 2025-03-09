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
    private let didFinishBinding: Binding<Bool>?

    init(images: [URL], didFinishBinding: Binding<Bool>? = nil) {
        _viewModel = StateObject(wrappedValue:
            ImageSequenceViewModel(images: images))
        self.didFinishBinding = didFinishBinding
    }

    var body: some View {
        SpriteView(scene: viewModel.scene)
            .onAppear {
                viewModel.start()
            }
            .onDisappear {
                viewModel.stop()
            }
            .onReceive(viewModel.timer) { _ in
                viewModel.update()
                if viewModel.hasFinishedPlaying {
                    didFinishBinding?.wrappedValue.toggle()
                }
            }
    }
}

#Preview {
    let animations = AnimationCollection.from(files: Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])

    ImageSequenceView(images: animations["SS001"]!.randomAnimation().urls)
}
