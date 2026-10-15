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
    @StateObject private var screenSaverStopObserver = DistributedNotificationObserver(name: .screenSaverWillStop)
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
            .onReceive(screenSaverStopObserver.publisher) { _ in
                if #available(macOS 26, *) {
                    // Delay to prevent screensaver from restarting automatically without blocking the main runloop.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        NSApplication.shared.terminate(nil)
                    }
                } else {
                    NSApplication.shared.terminate(nil)
                }
            }
    }
}

#Preview {
    SnoopyView()
}
