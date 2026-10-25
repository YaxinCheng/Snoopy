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
}
