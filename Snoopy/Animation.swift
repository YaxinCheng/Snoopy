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
private let ALL_PREFIX_LEN: Int = "101_".count
private let IMAGE_SEQUENCE_MAX: Int = 201

enum Animation: Equatable {
    case video(Clip<URL>)
    case imageSequence(Clip<ImageSequence>)
    
    init<S: StringProtocol, T: StringProtocol>(name: S, type: T) {
        switch type {
        case "mov": self = .video(Clip(name: String(name)))
        case "heic": self = .imageSequence(Clip(name: String(name)))
        default:
            fatalError("Unsupported clip type: \(type)")
        }
    }
    
    init(clip: Clip<URL>) {
        self = .video(clip)
    }
    
    init(clip: Clip<ImageSequence>) {
        self = .imageSequence(clip)
    }
    
    var urls: [URL] {
        switch self {
        case .video(let clip):
            [clip.intro] + OptionalToArray(clip.loop) + OptionalToArray(clip.outro)
        case .imageSequence(let clip):
            clip.intro.urls + OptionalToArray(clip.loop?.urls) + OptionalToArray(clip.outro?.urls)
        }
    }
}

struct AnimationCollection {
    let animations: AnimationDict // clip name to clip
    let specialImages: [URL] // images that will be used as decorations
    
    private init(clips: [String: Animation], specialImages: [URL]) {
        self.animations = clips
        self.specialImages = specialImages
    }
    
    static func from(files: [URL]) -> AnimationCollection {
        var fileNameSet = Set(files.lazy.map { $0.deletingPathExtension().lastPathComponent })
        var grouped: [String: Animation] = [:]
        var specialImages: [URL] = []
        for fileURL in files {
            let fileExtension = fileURL.pathExtension
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            guard let parsedName = parse(fileName: fileName) else {
                continue
            }
            if fileExtension == "heic" {
                if isSnoopyHouse(clipName: parsedName.clipName) {
                    specialImages.append(fileURL)
                    continue
                } else if !fileNameSet.contains(fileName) {
                    continue
                }
            }
            let animationState = String(parsedName.clipName)
            if grouped[animationState] == nil {
                grouped[animationState] = Animation(name: animationState, type: fileExtension)
            }
            switch grouped[animationState]! {
            case .video(let animation):
                grouped[animationState] = Animation(
                    clip: configClip(animation, parsedName: parsedName, sourceFile: fileURL))
            case .imageSequence(let animation):
                let template = findImageSequenceNameTemplate(fileName: fileName)
                let limit = findImageSequenceLimit(fileNames: fileNameSet, fileNameTemplate: template)
                for i in 0 ... limit {
                    fileNameSet.remove(String(format: template, i))
                }
                let imageSequence = ImageSequence(template: template,
                                                  lastFile: limit,
                                                  baseURL: fileURL.deletingLastPathComponent())
                grouped[animationState] = Animation(clip:
                    configClip(animation, parsedName: parsedName, sourceFile: imageSequence))
            }
        }
        return AnimationCollection(clips: grouped, specialImages: specialImages)
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
            let component = components[index]
            if component == "From" {
                parsed.from = components[index + 1]
                index += 1
            } else if component == "To" {
                parsed.to = components[index + 1]
                index += 1
            }
            // one name can only be either intro, outro, or loop, or none.
            parsed.isIntro = parsed.isIntro || component == "Intro" || component == "From"
            parsed.isOutro = !parsed.isIntro && (parsed.isOutro || component == "Outro" || component == "To")
            parsed.isLoop = !parsed.isIntro && !parsed.isOutro && (parsed.isLoop || component == "Loop")
            index += 1
        }
        return parsed
    }
    
    private static func isSnoopyHouse<S: StringProtocol>(clipName: S) -> Bool {
        clipName.starts(with: "IS")
    }
    
    private static func configClip<FileType>(_ clip: Clip<FileType>,
                                             parsedName: ParsedFileName,
                                             sourceFile: FileType) -> Clip<FileType>
    {
        var mutableAnimation = clip
        if let from = parsedName.from.map(String.init) {
            mutableAnimation.from = from
        }
        if let to = parsedName.to.map(String.init) {
            mutableAnimation.to = to
        }
        let hasBothFromAndTo = false // parsedName.from != nil && parsedName.to != nil
        let hasNeitherFromAndTo = parsedName.from == nil && parsedName.to == nil
        if parsedName.isLoop {
            mutableAnimation.loop = sourceFile
        } else if parsedName.isOutro {
            mutableAnimation.outro = sourceFile
        } else if parsedName.isIntro || hasBothFromAndTo || hasNeitherFromAndTo {
            mutableAnimation.intro = sourceFile
        }
        return mutableAnimation
    }
    
    private static func findImageSequenceNameTemplate(fileName: String) -> String {
        let lastUnderscore = fileName.lastIndex(of: "_") ?? fileName.endIndex
        let baseName = fileName[..<lastUnderscore]
        return "\(baseName)_%06d"
    }
    
    /// findImageSeuqenceLimit uses binary search to find the last image of a image sequence.
    private static func findImageSequenceLimit(fileNames: Set<String>, fileNameTemplate: String) -> UInt8 {
        var left = 0
        var right = IMAGE_SEQUENCE_MAX
        while left < right {
            let mid = left + (right - left) / 2
            let candidate = String(format: fileNameTemplate, mid)
            if fileNames.contains(candidate) {
                left = mid + 1
            } else {
                right = mid
            }
        }
        return UInt8(right - 1)
    }
}

extension AnimationCollection: Collection {
    typealias AnimationDict = Dictionary<String, Animation>
    typealias Index = AnimationDict.Index
    typealias Element = AnimationDict.Element
    
    subscript(index: AnimationDict.Index) -> AnimationDict.Element {
        animations[index]
    }
    
    subscript(key: AnimationDict.Key) -> AnimationDict.Value? {
        animations[key]
    }
    
    func index(after i: AnimationDict.Index) -> AnimationDict.Index {
        animations.index(after: i)
    }
    
    var startIndex: AnimationDict.Index {
        animations.startIndex
    }
    
    var endIndex: AnimationDict.Index {
        animations.endIndex
    }
    
    var keys: AnimationDict.Keys {
        animations.keys
    }
    
    var values: AnimationDict.Values {
        animations.values
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
///
/// # Types of Animations:
///   * Intro from another animation (Intro From)
///   * Intro from any animation (Intro)
///   * Loop (loop)
///   * Outro to any animation (Outro)
///   * Outro to another animation (Outro To or To)
///   * Whole animation (From To / No From,  no To, no Intro, no Outro)
///
struct Clip<FileType: Equatable>: Equatable {
    let name: String
    var from: String?
    var to: String?
    
    var intro: FileType!
    var loop: FileType?
    var outro: FileType?
}

/// ImageSequence files are a series of heic images that can be played one by one to form an animation.
struct ImageSequence: Equatable {
    /// template is the file name template missing the index number.
    /// The full file name can be reconstructed through String(format: template, $number).
    /// *Note*: the reconstructed file name does not include the extension.
    let template: String
    let lastFile: UInt8
    let baseURL: URL
    
    private func fileNameWithExtension(at index: UInt8) -> String {
        String(format: "\(template).heic", index)
    }
    
    /// urls returns
    var urls: [URL] {
        (0 ... lastFile)
            .map { self.fileNameWithExtension(at: $0) }
            .map { self.baseURL.appendingPathComponent($0) }
    }
}
