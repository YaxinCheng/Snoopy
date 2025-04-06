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
private let HEIC_FILE_TYPE: String = "heic"
private let MOV_FILE_TYPE: String = "mov"
private let DESIGNATION_KEYWORD: String = "_To_"

enum Animation: Equatable, Hashable {
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
    
    /// designated animations are the ones that jumps to a specific animation.
    /// One way to identify them is through the file names, where `_To_` keyword must present.
    fileprivate var designated: Bool {
        switch self {
        case .video(let clip):
            clip.outro?.lastPathComponent.contains(DESIGNATION_KEYWORD) ?? false
        case .imageSequence(let clip):
            clip.outro?.template.contains(DESIGNATION_KEYWORD) ?? false
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

// For debugging purposes only.
extension Animation: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .imageSequence(let imageSequence):
            return "{name: \(imageSequence.name), intro: \(imageSequence.intro?.urls.first?.lastPathComponent ?? "nil"), loop: \(imageSequence.loop?.urls.first?.lastPathComponent ?? "nil"), outro: \(imageSequence.outro?.urls.first?.lastPathComponent ?? "nil")}"
        case .video(let video):
            return "{name: \(video.name), intro: \(video.intro?.lastPathComponent ?? "nil"), loop: \(video.loop?.lastPathComponent ?? "nil"), outro: \(video.outro?.lastPathComponent ?? "nil")}"
        }
    }
}

/// AnimationCollection is a data structure that stores all the animations.
/// It is a map that maps the relation that one animation can jump to one or multiple other animations.
struct AnimationCollection {
    typealias JumpGraph = [Animation: [Animation]]
    
    let animations: JumpGraph // key: Animation, value: animations can be jumpped from the current animation
    let specialImages: [URL] // images that will be used as decorations
    let background: URL?
    
    private init(graph: JumpGraph, specialImages: [URL], background: URL?) {
        self.animations = graph
        self.specialImages = specialImages
        self.background = background
    }
    
    static func from(files: [URL]) -> AnimationCollection {
        let files = files.sorted { $0.path() < $1.path() }
        var specialImages: [URL] = []
        var background: URL?
        var allContexts = [AnimationContext]()
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
                let endOfAnimationIndex = files[index...].findFirstUnmatch {
                    $0.lastPathComponent.range(of: "^\\d{3}_\(parsedName.resourceName).*\\.(heic|mov)$", options: .regularExpression) != nil
                }
                let animationContexts: [AnimationContext] = switch fileExtension {
                case HEIC_FILE_TYPE:
                    constructImageSequenceAnimation(from: files[index ..< endOfAnimationIndex], resourceName: parsedName.resourceName)
                case MOV_FILE_TYPE:
                    constructVideoAnimation(from: files[index ..< endOfAnimationIndex])
                default:
                    fatalError("Unreachable: unexpected file type \(fileExtension)")
                }
                allContexts.append(contentsOf: animationContexts)
                index = endOfAnimationIndex - 1
            default:
                Log.error(msg: "Unexpected file type \(fileName)")
            }
        }
        return AnimationCollection(graph: createJumpGraph(context: allContexts),
                                   specialImages: specialImages, background: background)
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
    
    struct AnimationContext {
        let animation: Animation
        let source: Substring?
        let destination: Substring?
    }
    
    private static func constructVideoAnimation(from files: ArraySlice<URL>) -> [AnimationContext] {
        var currentClip: Clip<URL>?
        var source: Substring?
        var destination: Substring?
        var animations = [AnimationContext]()
        for file in files {
            guard let parsedName = parse(fileName: file.deletingPathExtension().lastPathComponent) else {
                fatalError("Unparseable file name for video: \(file.lastPathComponent)")
            }
            let clip = Clip.from(parsedName: parsedName, sourceFile: file)
            let mergedSuccessfully = currentClip?.tryMerge(clip) == true
            if mergedSuccessfully {
                source = source ?? parsedName.from
                destination = destination ?? parsedName.to
            } else {
                if let currentClip = currentClip {
                    animations.append(.init(animation: Animation(clip: currentClip), source: source, destination: destination))
                }
                currentClip = clip
                source = parsedName.from
                destination = parsedName.to
            }
        }
        animations.append(.init(animation: Animation(clip: currentClip!), source: source, destination: destination))
        return animations
    }
    
    private static func constructImageSequenceAnimation(from files: ArraySlice<URL>, resourceName: some StringProtocol) -> [AnimationContext] {
        var introClip: Clip<ImageSequence>?
        var outroClips: [(Clip<ImageSequence>, Substring?)] = []
        var animations = [AnimationContext]()
        var source: Substring?
        var destination: Substring?
        var index = files.startIndex
        while index < files.endIndex {
            let fileName = files[index].deletingPathExtension().lastPathComponent
            let template = extractNameTemplate(fileName: fileName)
            let endIndexOfClip = files[index...].findFirstUnmatch {
                $0.lastPathComponent.range(of: "\(template)\\d{6}.heic", options: .regularExpression) != nil
            }
            let imageSequence = ImageSequence(template: String(template),
                                              lastFile: UInt8(endIndexOfClip - index - 1),
                                              baseURL: files[index].deletingLastPathComponent())
            let parsedName = parse(fileName: fileName)!
            let clip = Clip.from(parsedName: parsedName, sourceFile: imageSequence)
            if clip.intro != nil {
                introClip = clip
                source = source ?? parsedName.from
                destination = destination ?? parsedName.to
            } else if clip.loop != nil { // there must be an intro if there is a loop, and since it's sorted, the intro comes first
                if introClip?.tryMerge(clip) != true {
                    fatalError("failed to merge intro and loop clip of \(resourceName)")
                }
            } else {
                outroClips.append((clip, parsedName.to))
            }
            index = endIndexOfClip
        }
        // Certain animations, like BP001 will have BP001, BP001_To_BP002, BP001_To_BP003, etc.
        // The goal here is to make multiple animations:
        // * Intro: BP001
        // * Intro: BP001, Outro: BP002
        // * Intro: BP001, Outro: BP003
        if outroClips.isEmpty || (introClip != nil && outroClips.allSatisfy { $0.1 != nil }) {
            animations.append(.init(animation: Animation(clip: introClip!), source: source, destination: destination))
        }
        for (var outroClip, destination) in outroClips {
            guard introClip == nil || outroClip.tryMerge(introClip!) else {
                fatalError("failed to merge intro and outro clip of \(resourceName)")
            }
            animations.append(.init(animation: Animation(clip: outroClip), source: source, destination: destination))
        }
        return animations
    }
    
    private static func extractNameTemplate(fileName: String) -> Substring {
        let lastUnderscore = fileName.lastIndex(of: "_")
        assert(lastUnderscore != nil, "found file name with no underscore: \(fileName)")
        return fileName[...lastUnderscore!]
    }
    
    private static func createJumpGraph(context: [AnimationContext]) -> JumpGraph {
        var nameToAnimations = [String: [Animation]]()
        for c in context {
            let animationName = String(c.animation.name)
            if nameToAnimations[animationName] == nil {
                nameToAnimations[animationName] = []
            }
            nameToAnimations[animationName]?.append(c.animation)
        }
        var jumpGraph: JumpGraph = [:]
        for c in context {
            jumpGraph[c.animation] = []
        }
        for c in context {
            if let source = c.source.map(String.init) {
                nameToAnimations[source]?
                    .filter { !$0.designated }
                    .forEach { jumpGraph[$0]?.append(c.animation) }
            }
            if let destination = c.destination.map(String.init),
               let destinationAnimation = nameToAnimations[destination]
            {
                jumpGraph[c.animation]?.append(contentsOf: destinationAnimation)
            }
        }
        return jumpGraph
    }
}

extension AnimationCollection: Collection {
    typealias Index = JumpGraph.Index
    typealias Element = JumpGraph.Element
    
    subscript(index: JumpGraph.Index) -> JumpGraph.Element {
        animations[index]
    }
    
    subscript(key: JumpGraph.Key) -> JumpGraph.Value? {
        animations[key]
    }
    
    func index(after i: JumpGraph.Index) -> JumpGraph.Index {
        animations.index(after: i)
    }
    
    var startIndex: JumpGraph.Index {
        animations.startIndex
    }
    
    var endIndex: JumpGraph.Index {
        animations.endIndex
    }
    
    var keys: JumpGraph.Keys {
        animations.keys
    }
    
    var values: JumpGraph.Values {
        animations.values
    }
}

/// Animation is a an abstraction for a group of content needs to be played.
/// # parameters:
///   * name - is the name of the group of files. Normally the prefix shared by these files. A state. Like `SS001`.
///   * intro - the file that contains the intro of this animation.
///     * Some animation may itself be a whole animation combining intro + loop + outro. In this case, we use this field as well and set other fields empty.
///   * loop - the file that contains the loop content of the animation.
///   * outro - the file that contains the outro content of the animation.
///     * It is possible for some animation to have only outro but not intro or loop.
///
/// # Types of Animations:
///   * Intro from another animation (Intro From)
///   * Intro from any animation (Intro)
///   * Loop (loop)
///   * Outro to any animation (Outro)
///   * Outro to another animation (Outro To or To)
///   * Whole animation (From To / No From,  no To, no Intro, no Outro)
///
struct Clip<MediaType>: Equatable, Hashable where MediaType: Equatable, MediaType: Hashable {
    let name: String
    
    var intro: MediaType?
    var loop: MediaType?
    var outro: MediaType?
    
    fileprivate static func from(parsedName: AnimationCollection.ParsedFileName, sourceFile: MediaType) -> Self {
        var clip = Clip(name: String(parsedName.resourceName))
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
        intro = intro ?? other.intro
        loop = loop ?? other.loop
        outro = outro ?? other.outro
        return true
    }
}

/// ImageSequence files are a series of heic images that can be played one by one to form an animation.
struct ImageSequence: Equatable, Hashable {
    /// template is the file name template missing the index number.
    ///
    /// Specifically, it is the prefix of a file name without extension or indexing number.
    ///
    /// For example, *"000\_Background\_"*.
    ///
    /// The full file name can be reconstructed through `String(format: "\(template)%06d.heic", $number)`.
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
