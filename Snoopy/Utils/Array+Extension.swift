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

extension ArraySlice {
    /// findFirstUnmatch finds the first index where the file does not match with passed in matcher.
    /// **Note**: The source needs to be sorted.
    func findFirstUnmatch(matches: (Element) -> Bool) -> Int {
        var left = startIndex
        var right = endIndex
        while left < right {
            let mid = left + (right - left) / 2
            if matches(self[mid]) {
                left = mid + 1
            } else {
                right = mid
            }
        }
        return right
    }
}
