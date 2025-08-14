//
//  ParsedFileName.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-04-06.
//

import Foundation

// VI, WE: sun / moon / other weather for snoopy on the roof
// AS: dream content
// ST dream transition: hide dreams and enter sleepy snoopy on roof mode
// TM: dream masks
// IS: Snoopy houses
//
// Exception: A B suffix found for 103_ST003_Hide_A.mov 103_ST003_Hide_B.mov
//
// Hide -> Hide dream and show sleepy snoopy -> Intro
// Reveal -> Show dream and hide sleepy snoopy -> Outro
struct ParsedFileName {
    var resourceName: Substring
    var from: Substring? = nil
    var to: Substring? = nil
    var isIntro: Bool = false // Intro, From, Hide
    var isLoop: Bool = false
    var isOutro: Bool = false // Outro, To, Reveal
    var isMask: Bool = false
    var isOutline: Bool = false
    var isHideOrReveal: Bool = false // Hide, Reveal

    /// Parse file names into components.
    static func from(fileName: String) -> ParsedFileName {
        let components = fileName.split(separator: "_")
        var parsed = ParsedFileName(resourceName: components[1])

        var index = 2
        while index < components.count {
            let component = components[index]
            if component == "From" {
                parsed.from = components[index + 1]
                index += 1
            } else if component == "To" {
                parsed.to = components[index + 1]
                index += 1
            }
            // one name can only be either intro, outro, or loop, or none.
            parsed.isIntro = parsed.isIntro || ["Intro", "From", "Reveal"].contains(component)
            parsed.isOutro = !parsed.isIntro && (parsed.isOutro || ["Outro", "To", "Hide"].contains(component))
            parsed.isLoop = !parsed.isIntro && !parsed.isOutro && (parsed.isLoop || component == "Loop")
            parsed.isHideOrReveal = parsed.isHideOrReveal || ["Hide", "Reveal"].contains(component)
            parsed.isMask = parsed.isMask || component == "Mask"
            parsed.isOutline = parsed.isOutline || component == "Outline"
            index += 1
        }
        return parsed
    }

    /// Get the resource name from a file name.
    /// A file name is generally in the format of `000_ResourceName_Other_Parts`,
    /// and all we need is the `ResourceName` part.
    ///
    /// There are two special cases:
    /// 1. `HasNoUnderscore`, its resource name is itself
    /// 2. `000_NoSecondUnderscore`, its resource name is `NoSecondUnderscore`
    static func extractResourceName(from fileName: String) -> Substring {
        guard let firstUnderscore = fileName.firstIndex(of: "_") else {
            return fileName[...]
        }
        let startIndex = fileName.index(after: firstUnderscore)
        let secondUnderscore = fileName[startIndex...].firstIndex(of: "_") ?? fileName.endIndex
        return fileName[startIndex ..< secondUnderscore]
    }

    /// Extract the prefix for associated image sequence files.
    /// An image sequence has a shared prefix `000_ResourceName_Status_000000.heic`,
    /// and the shared prefix we want is `000_ResourceName_Status_`.
    ///
    /// **Warning**: The function crashes if there is not underscore.
    static func extractImageSequenceNamePrefix(fileName: String) -> Substring {
        let lastUnderscore = fileName.lastIndex(of: "_")
        #if DEBUG
        guard lastUnderscore != nil else {
            Log.fault("found file name with no underscore: \(fileName)")
        }
        #endif
        return fileName[...lastUnderscore!]
    }

    static func isSnoopyHouse<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "IS")
    }

    static func isBackground<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName == "Background"
    }

    static func isDream<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "AS")
    }

    static func isDreamTransition<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "ST")
    }

    static func isMask<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "TM")
    }

    static func isRph<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName == "RPH"
    }

    static func isDecoration<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "IV") || resourceName.starts(with: "WE")
    }

    static func isSpecialTransition<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName == "ST006"
    }
}
