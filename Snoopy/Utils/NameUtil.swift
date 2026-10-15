//
//  NameUtil.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2026-10-13.
//

enum NameUtil {
    /// Get the resource name from a file name.
    /// A file name is generally in the format of `000_ResourceName_Other_Parts`,
    /// and all we need is the `ResourceName` part.
    ///
    /// There are 3 special cases:
    /// 1. `HasNoUnderscore`, its resource name is itself
    /// 2. `000_NoSecondUnderscore`, its resource name is `NoSecondUnderscore`
    /// 3. `RPD`, `RWD`, `RWH` are 3 cases where the intro is named as RXX001 while other files refer to it as RXX
    static func extractResourceName(from fileName: String) -> Substring {
        guard let firstUnderscore = fileName.firstIndex(of: "_") else {
            return fileName[...]
        }
        let startIndex = fileName.index(after: firstUnderscore)
        let secondUnderscore = fileName[startIndex...].firstIndex(of: "_") ?? fileName.endIndex
        let resourceName = fileName[startIndex ..< secondUnderscore]
        if !resourceName.starts(with: "R") {
            return resourceName
        } else {
            return splitAnimationName(resourceName).0
        }
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

    static func isRoofPose<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "RP")
    }

    static func isDecoration<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "VI") || resourceName.starts(with: "WE")
    }

    static func isSpecialTransition<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName == "ST006"
    }

    static func splitAnimationName<S: StringProtocol>(_ name: S) -> (S.SubSequence, S.SubSequence) {
        let splitIndex = name.firstIndex(where: \.isNumber) ?? name.endIndex
        return (name[..<splitIndex], name[splitIndex...])
    }
}
