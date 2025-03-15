//
//  MainView.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import Foundation
import ScreenSaver
import SwiftUI

class MainView: ScreenSaverView {
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
//        addSubview(toNSView(view: SnoopyView()))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        addSubview(toNSView(view: SnoopyView()))
    }

    private func toNSView(view: some View) -> NSView {
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.width, .height]
        return hostingController.view
    }
}
