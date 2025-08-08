//
//  Bundle+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-08.
//

import Foundation

extension Bundle {
    static var this: Bundle {
        Bundle(for: SnoopyScene.self)
    }
}
