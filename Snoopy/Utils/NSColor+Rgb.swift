//
//  NSColor+Rgb.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2026-10-15.
//

import Cocoa

extension NSColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1.0)
    }
}
