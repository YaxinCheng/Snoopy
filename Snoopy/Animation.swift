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
    "Mask",
    "Hide",
    "Reveal"
]
private let ALL_PREFIX_LEN: Int = "101_".count
private let IMAGE_SEQUENCE_MAX: Int = 201
private let HEIC_FILE_TYPE: String = "heic"
private let MOV_FILE_TYPE: String = "mov"

struct AnimationBundle {
    private static let SINGLETON_TRANSITION_KEY = "$singleton"
    
    private var variations: [String: Animation]
    
    init(variations: [String: Animation] = [:]) {
        self.variations = variations
    }
    
    fileprivate mutating func add(animation: Animation) {
        let key = animation.to ?? Self.SINGLETON_TRANSITION_KEY
        if variations[key] != nil {
            fatalError("Adding animation to an existing variation")
        } else {
            variations[key] = animation
        }
    }
    
    func randomAnimation() -> Animation {
        variations.values.randomElement()!
    }
    
    func element(to destination: String? = nil) -> Animation? {
        variations[destination ?? Self.SINGLETON_TRANSITION_KEY]
    }
}

enum Animation: Equatable {
    case video(Clip<URL>)
    case imageSequence(Clip<ImageSequence>)
    
    init(clip: Clip<URL>) {
        self = .video(clip)
    }
    
    init(clip: Clip<ImageSequence>) {
        self = .imageSequence(clip)
    }
    
    var urls: [URL] {
        switch self {
        case .video(let clip):
            OptionalToArray(clip.intro) + OptionalToArray(clip.loop) + OptionalToArray(clip.outro)
        case .imageSequence(let clip):
            OptionalToArray(clip.intro?.urls) + OptionalToArray(clip.loop?.urls) + OptionalToArray(clip.outro?.urls)
        }
    }
    
    var to: String? {
        switch self {
        case .video(let clip):
            clip.to
        case .imageSequence(let clip):
            clip.to
        }
    }
    
    var name: String {
        switch self {
        case .video(let clip):
            clip.name
        case .imageSequence(let clip):
            clip.name
        }
    }
}

struct AnimationCollection {
    typealias AnimationDict = [String: AnimationBundle]
    
    let animations: AnimationDict // clip name to clip
    let specialImages: [URL] // images that will be used as decorations
    let background: URL?
    
    private init(clips: AnimationDict, specialImages: [URL], background: URL?) {
        self.animations = clips
        self.specialImages = specialImages
        self.background = background
    }
    
    static func from(files: [URL]) -> AnimationCollection {
        let files = files.sorted { $0.path() < $1.path() }
        var grouped: AnimationDict = [:]
        var specialImages: [URL] = []
        var background: URL?
        var index = 0
        while index < files.count {
            defer { index += 1 }
            let fileURL = files[index]
            let fileExtension = fileURL.pathExtension
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            guard let parsedName = parse(fileName: fileName) else {
                continue
            }
            switch fileExtension {
            case HEIC_FILE_TYPE where isSnoopyHouse(parsedName.resourceName):
                specialImages.append(fileURL)
            case HEIC_FILE_TYPE where isBackground(parsedName.resourceName):
                background = fileURL
            case HEIC_FILE_TYPE, MOV_FILE_TYPE:
                let endOfAnimationIndex = findFirstUnmatch(source: files[index...]) {
                    $0.lastPathComponent.range(of: "^\\d{3}_\(parsedName.resourceName).*\\.(heic|mov)$", options: .regularExpression) != nil
                }
                let animations: [Animation]
                if fileExtension == HEIC_FILE_TYPE {
                    animations = constructImageSequenceAnimation(from: files[index ..< endOfAnimationIndex])
                } else if fileExtension == MOV_FILE_TYPE {
                    animations = constructVideoAnimation(from: files[index ..< endOfAnimationIndex])
                } else {
                    fatalError("Unreachable: unexpected file type \(fileExtension)")
                }
                for animation in animations {
                    appendAnimation(animation, target: &grouped)
                }
                index = endOfAnimationIndex - 1
            default:
//                fatalError("Unexpected file type \(fileName)")
                Log.error(msg: "Unexpected file type \(fileName)")
            }
        }
        return AnimationCollection(clips: grouped, specialImages: specialImages, background: background)
    }
    
    struct ParsedFileName {
        var resourceName: Substring
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
        var parsed = ParsedFileName(resourceName: components[1])
        
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
    
    private static func isSnoopyHouse<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName.starts(with: "IS")
    }
    
    private static func isBackground<S: StringProtocol>(_ resourceName: S) -> Bool {
        resourceName == "Background"
    }
    
    private static func constructVideoAnimation(from files: ArraySlice<URL>) -> [Animation] {
        var currentClip: Clip<URL>?
        var animations = [Animation]()
        for file in files {
            guard let parsedName = parse(fileName: file.deletingPathExtension().lastPathComponent) else {
                fatalError("Unparseable file name for video: \(file.lastPathComponent)")
            }
            let clip = Clip.from(parsedName: parsedName, sourceFile: file)
            if currentClip?.tryMerge(clip) != true {
                if let currentClip = currentClip {
                    animations.append(Animation(clip: currentClip))
                }
                currentClip = clip
            }
        }
        animations.append(Animation(clip: currentClip!))
        return animations
    }
    
    private static func constructImageSequenceAnimation(from files: ArraySlice<URL>) -> [Animation] {
        var currentClip: Clip<ImageSequence>?
        var animations = [Animation]()
        var index = files.startIndex
        while index < files.endIndex {
            let fileName = files[index].deletingPathExtension().lastPathComponent
            let template = extractNameTemplate(fileName: fileName)
            let endIndexOfClip = findFirstUnmatch(source: files[index...]) {
                $0.lastPathComponent.range(of: "\(template)\\d{6}.heic", options: .regularExpression) != nil
            }
            let imageSequence = ImageSequence(template: template,
                                              lastFile: UInt8(endIndexOfClip - index - 1),
                                              baseURL: files[index].deletingLastPathComponent())
            let clip = Clip.from(parsedName: parse(fileName: fileName)!, sourceFile: imageSequence)
            if currentClip?.tryMerge(clip) != true {
                if let currentClip = currentClip {
                    animations.append(Animation(clip: currentClip))
                }
                currentClip = clip
            }
            index = endIndexOfClip
        }
        animations.append(Animation(clip: currentClip!))
        return animations
    }
    
    private static func extractNameTemplate(fileName: String) -> String {
        let lastUnderscore = fileName.lastIndex(of: "_") ?? fileName.endIndex
        let baseName = fileName[..<lastUnderscore]
        return "\(baseName)_"
    }
    
    /// findFirstUnmatch finds the first index where the file does not match with passed in matcher.
    /// **Note**: The source needs to be sorted.
    private static func findFirstUnmatch<T>(source: ArraySlice<T>, matches: (T) -> Bool) -> Int {
        var left = source.startIndex
        var right = source.endIndex
        while left < right {
            let mid = left + (right - left) / 2
            if matches(source[mid]) {
                left = mid + 1
            } else {
                right = mid
            }
        }
        return right
    }
    
    private static func appendAnimation(_ animation: Animation, target: inout AnimationDict) {
        if target[animation.name] == nil {
            target[animation.name] = AnimationBundle()
        }
        target[animation.name]?.add(animation: animation)
    }
}

extension AnimationCollection: Collection {
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
struct Clip<MediaType: Equatable>: Equatable {
    let name: String
    var from: String?
    var to: String?
    
    var intro: MediaType?
    var loop: MediaType?
    var outro: MediaType?
    
    static func from(parsedName: AnimationCollection.ParsedFileName, sourceFile: MediaType) -> Self {
        var clip = Clip(name: String(parsedName.resourceName))
        clip.from = parsedName.from.map(String.init)
        clip.to = parsedName.to.map(String.init)
        if parsedName.isLoop {
            clip.loop = sourceFile
        } else if parsedName.isOutro {
            clip.outro = sourceFile
        } else {
            clip.intro = sourceFile
        }
        return clip
    }
    
    mutating func tryMerge(_ other: Self) -> Bool {
        assert(name == other.name, "Cannot merge clips with different names: want \(name), got \(other.name)")
        if (intro != nil && other.intro != nil)
            || (outro != nil && other.outro != nil)
            || (loop != nil && other.loop != nil)
        {
            return false
        }
        from = from ?? other.from
        to = to ?? other.to
        intro = intro ?? other.intro
        loop = loop ?? other.loop
        outro = outro ?? other.outro
        return true
    }
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
        String(format: "\(template)%06d.heic", index)
    }
    
    /// urls returns
    var urls: [URL] {
        (0 ... lastFile)
            .map { self.fileNameWithExtension(at: $0) }
            .map { self.baseURL.appendingPathComponent($0) }
    }
}
