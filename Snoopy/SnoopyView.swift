//
//  SnoopyView.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import Foundation
import ScreenSaver

class SnoopyView: ScreenSaverView {
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
