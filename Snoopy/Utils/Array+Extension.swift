//
//  Array+Extension.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import Foundation

extension Array {
    func `repeat`(count: UInt) -> LazySequence<some Sequence<Element>> {
        (0 ..< count).lazy.flatMap { _ in self }
    }
}
