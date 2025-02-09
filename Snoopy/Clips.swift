//
//  Clips.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import Foundation

// Ignore these two types of files as I don't know how to handle them yet.
private let IGNORED_KEYWORDS: Set<String> = [
    "Outline",
    "Mask"
]
private let SPECIAL_IMAGE_PREFIX: String = "IS"
private let ALL_PREFIX_LEN: Int = "101_".count
private let IMAGE_SEQUENCE_MAX: Int = 201

enum Clip {
    case video(Animation<URL>)
    case imageSequence(Animation<ImageSequence>)
    
    init(name: String, type: String) {
        switch type {
        case "mov": self = .video(Animation(name: name))
        case "heic": self = .imageSequence(Animation(name: name))
        default:
            fatalError("Unsupported clip type: \(type)")
        }
    }
    
    init(animation: Animation<URL>) {
        self = .video(animation)
    }
    
    init(animation: Animation<ImageSequence>) {
        self = .imageSequence(animation)
    }
}

struct ClipGroup {
    private let clips: [String: Clip] // clip name to clip
    private let specialImages: [URL] // images that will be used as decorations
    
    private init(clips: [String: Clip], specialImages: [URL]) {
        self.clips = clips
        self.specialImages = specialImages
    }
    
    private static func groupFiles(_ files: [URL]) -> ClipGroup {
        let fileNameSet = Set(files.lazy.map { $0.deletingPathExtension().lastPathComponent })
        var grouped: [String: Clip] = [:]
        var specialImages: [URL] = []
        for fileURL in files {
            let fileExtension = fileURL.pathExtension
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            guard let parsedName = parse(fileName: fileName) else {
                continue
            }
            let animationName = String(parsedName.clipName)
            if grouped[animationName] == nil {
                grouped[animationName] = Clip(name: animationName, type: fileExtension)
            }
            switch grouped[animationName]! {
            case .video(var animation):
                grouped[animationName] = Clip(
                    animation: configAnimation(animation, parsedName: parsedName, sourceFile: fileURL))
            case .imageSequence(var animation):
                let limit = findImageSequenceLimit(fileNames: fileNameSet, fileName: fileName)
                grouped[animationName] = Clip(animation:
                    configAnimation(animation,
                                    parsedName: parsedName,
                                    sourceFile: ImageSequence(name: animationName, lastFile: limit)))
            }
        }
        return ClipGroup(clips: grouped, specialImages: specialImages)
    }
    
    struct ParsedFileName {
        var clipName: Substring
        var from: Substring? = nil
        var to: Substring? = nil
        var isIntro: Bool = false
        var isLoop: Bool = false
        var isOutro: Bool = false
    }
    
    /// Parse file names into components.
    ///
    /// **Note**: the current version will ignore files with the words
    /// appeared in the IGNORED_KEYWORDS
    private static func parse(fileName: String) -> ParsedFileName? {
        let components = fileName.split(separator: "_")
        var parsed = ParsedFileName(clipName: components[1])
        
        var index = 2
        while index < components.count {
            // TODO: remove this logic after figuring out how to handle masks and outlines.
            if IGNORED_KEYWORDS.contains(where: { $0 == components[index] }) {
                return nil
            }
            if components[index] == "From" {
                parsed.from = components[index + 1]
                index += 1
            } else if components[index] == "To" {
                parsed.to = components[index + 1]
                index += 1
            } else {
                parsed.isLoop = components[index] == "Intro"
                parsed.isOutro = components[index] == "Outro"
                parsed.isLoop = components[index] == "Loop"
            }
            index += 1
        }
        return parsed
    }
    
    private static func configAnimation<FileType>(_ animation: Animation<FileType>,
                                                  parsedName: ParsedFileName,
                                                  sourceFile: FileType) -> Animation<FileType>
    {
        var animation = animation
        animation.from = parsedName.from.map(String.init)
        animation.to = parsedName.to.map(String.init)
        if parsedName.isIntro {
            animation.intro = sourceFile
        } else if parsedName.isLoop {
            animation.loop = sourceFile
        } else if parsedName.isOutro {
            animation.outro = sourceFile
        }
        return animation
    }
    
    /// findImageSeuqenceLimit uses binary search to find the last image of a image sequence.
    private static func findImageSequenceLimit(fileNames: Set<String>, fileName: String) -> UInt8 {
        let lastUnderscore = fileName.lastIndex(of: "_") ?? fileName.endIndex
        let baseName = fileName[..<lastUnderscore]
        var left = 0
        var right = IMAGE_SEQUENCE_MAX
        while left < right {
            let mid = left + (right - left) / 2
            let candidate = String(format: "\(baseName)_%06d.heic", mid)
            if fileNames.contains(candidate) {
                left = mid + 1
            } else {
                right = mid
            }
        }
        return UInt8(right - 1)
    }
}

/// Animation is a an abstraction for a group of content needs to be played.
/// # parameters:
///   * name - is the name of the group of files. Normally the prefix shared by these files. A state. Like `SS001`.
///   * from - where this animation can been transited from. Can be nil if this animation can never be transited from any other animation.
///   * to - where this animation can transit to. Can be nil if there is no next animation.
///   * intro - the file that contains the intro of this animation.
///     * Some animation may itself be a whole animation combining intro + loop + outro. In this case, we use this field as well and set other fields empty.
///   * loop - the file that contains the loop content of the animation.
///   * outro - the file that contains the outro content of the animation.
struct Animation<FileType> {
    let name: String
    var from: String?
    var to: String?
    
    var intro: FileType!
    var loop: FileType?
    var outro: FileType?
}

/// ImageSequence files are a series of heic images that can be played one by one to form an animation.
struct ImageSequence {
    let name: String
    let lastFile: UInt8
}
