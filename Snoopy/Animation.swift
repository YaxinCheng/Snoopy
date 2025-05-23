//
//  Clips.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import Foundation

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
            clip.outro?.prefix.contains(DESIGNATION_KEYWORD) ?? false
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
    
    var kind: ClipKind {
        switch self {
        case .video(let clip):
            clip.kind
        case .imageSequence(let clip):
            clip.kind
        }
    }
    
    func unwrapToImageSequence() -> Clip<ImageSequence> {
        switch self {
        case .imageSequence(let clip): clip
        case .video: Log.fault("trying to unwrap a video clip to an image sequence clip")
        }
    }
    
    func unwrapToVideo() -> Clip<URL> {
        switch self {
        case .video(let clip): clip
        case .imageSequence: Log.fault("trying to unwrap an image sequence clip to a video clip")
        }
    }
}

#if DEBUG
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
#endif

struct Mask {
    private var _animations: [Clip<ImageSequence>?] = [nil, nil]
    
    fileprivate mutating func add(animation: Animation) {
        let clip = animation.unwrapToImageSequence()
        _animations[clip.kind.rawValue] = clip
    }
    
    var mask: Clip<ImageSequence> {
        _animations[ClipKind.mask.rawValue]!
    }
    
    var outline: Clip<ImageSequence> {
        _animations[ClipKind.outline.rawValue]!
    }
}

/// AnimationCollection is a data structure that stores all the animations.
/// It is a map that maps the relation that one animation can jump to one or multiple other animations.
struct AnimationCollection {
    typealias JumpGraph = [Animation: [Animation]]
    
    let jumpGraph: JumpGraph // key: Animation, value: animations can be jumpped from the current animation
    let masks: [Mask]
    let dreams: [Animation]
    let dreamTransitions: [Animation]
    let decorations: [Animation]
    /// rph for lack of better terms is a kind of animation that bridges transition to and from sleepy snoopy.
    /// It will also be part of the jump graph.
    let rph: Set<Animation>
    let specialImages: [URL] // images that will be used as decorations
    let background: URL?
    
    private init(graph: JumpGraph, dreams: [Animation], dreamTransitions: [Animation], decorations: [Animation], rph: Set<Animation>, masks: [Mask], specialImages: [URL], background: URL?) {
        self.jumpGraph = graph
        self.dreams = dreams
        self.dreamTransitions = dreamTransitions
        self.decorations = decorations
        self.rph = rph
        self.masks = masks
        self.specialImages = specialImages
        self.background = background
    }
    
    static func from(files: [URL]) -> AnimationCollection {
        let files = files.sorted(using: FileSortComparator())
        var specialImages: [URL] = []
        var background: URL?
        var allContexts = [AnimationContext]()
        var masks: [String: Mask] = [:]
        var dreams: [Animation] = []
        var dreamTransitions: [Animation] = []
        var decorations: [Animation] = []
        var rph: Set<Animation> = []
        var index = 0
        while index < files.count {
            defer { index += 1 }
            let fileURL = files[index]
            let fileExtension = fileURL.pathExtension
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            if Self.isThumbnail(fileName) {
                continue
            }
            let resourceName = ParsedFileName.extractResourceName(from: fileName)
            switch fileExtension {
            case HEIC_FILE_TYPE where ParsedFileName.isSnoopyHouse(resourceName):
                specialImages.append(fileURL)
            case HEIC_FILE_TYPE where ParsedFileName.isBackground(resourceName):
                background = fileURL
            case HEIC_FILE_TYPE, MOV_FILE_TYPE:
                let endOfAnimationIndex = files[index...].findFirstUnmatch {
                    $0.lastPathComponent.range(of: "^\\d{3}_\(resourceName).*\\.(heic|mov)$", options: .regularExpression) != nil
                }
                let animationContexts: [AnimationContext] = switch fileExtension {
                case HEIC_FILE_TYPE:
                    constructImageSequenceAnimation(from: files[index ..< endOfAnimationIndex], resourceName: resourceName)
                case MOV_FILE_TYPE:
                    constructVideoAnimation(from: files[index ..< endOfAnimationIndex])
                default:
                    unreachable("unexpected file extension \"\(fileExtension)\", file is: \(fileURL.path())")
                }
                if ParsedFileName.isMask(resourceName) {
                    for animation in animationContexts.lazy.map(\.animation) {
                        masks.setDefault(Mask(), forKey: animation.name) {
                            $0.add(animation: animation)
                        }
                    }
                } else if ParsedFileName.isDream(resourceName) {
                    dreams.append(contentsOf: animationContexts.map(\.animation))
                } else if ParsedFileName.isDreamTransition(resourceName) {
                    dreamTransitions.append(contentsOf: animationContexts.map(\.animation))
                } else if ParsedFileName.isDecoration(resourceName) {
                    decorations.append(contentsOf: animationContexts.map(\.animation))
                } else {
                    if ParsedFileName.isRph(resourceName) {
                        rph.formUnion(animationContexts.lazy.map(\.animation))
                    }
                    allContexts.append(contentsOf: animationContexts)
                }
                index = endOfAnimationIndex - 1
            default:
                unreachable("unexpected file: \(fileURL.path())")
            }
        }
        return AnimationCollection(graph: createJumpGraph(context: allContexts),
                                   dreams: dreams,
                                   dreamTransitions: dreamTransitions,
                                   decorations: decorations,
                                   rph: rph,
                                   masks: Array(masks.values),
                                   specialImages: specialImages,
                                   background: background)
    }
    
    private static func isThumbnail(_ fileName: some StringProtocol) -> Bool {
        fileName.starts(with: "thumbnail")
    }
    
    typealias AnimationContext = (animation: Animation, source: Substring?, destination: Substring?)
    
    private static func constructVideoAnimation(from files: ArraySlice<URL>) -> [AnimationContext] {
        typealias ClipContext = (clip: Clip<URL>, source: Substring?, destination: Substring?)
        var introClips: [ClipContext] = []
        var loopClips: [Clip<URL>] = []
        var outroClips: [ClipContext] = []
        var animations = [AnimationContext]()
        for file in files {
            let parsedName = ParsedFileName.from(fileName: file.deletingPathExtension().lastPathComponent)
            let clip = Clip.from(parsedName: parsedName, sourceFile: file)
            if clip.intro != nil {
                introClips.append((clip, parsedName.from, parsedName.to))
            } else if clip.loop != nil {
                loopClips.append(clip)
            } else if clip.outro != nil {
                outroClips.append((clip, parsedName.from, parsedName.to))
            }
        }
        if !outroClips.isEmpty {
            for loopClip in loopClips {
                for index in introClips.indices {
                    if !introClips[index].clip.tryMerge(loopClip) {
                        Log.fault("merging introClip and loopClip failed! IntroClip: \(introClips[index].clip), loopClip: \(loopClip)")
                    }
                }
            }
            for outroClip in outroClips {
                for introClip in introClips {
                    var clip = introClip.clip
                    if !clip.tryMerge(outroClip.clip) {
                        Log.fault("merging introClip and outroClip failed! IntroClip: \(introClip.clip), outroClip: \(outroClip.clip)")
                    }
                    animations.append((Animation(clip: clip), introClip.source ?? outroClip.source, outroClip.destination ?? introClip.destination))
                }
            }
        } else {
            for clip in introClips {
                animations.append((Animation(clip: clip.clip), clip.source, clip.destination))
            }
        }
        return animations
    }
    
    private static func constructImageSequenceAnimation(from files: ArraySlice<URL>, resourceName: some StringProtocol) -> [AnimationContext] {
        var introClips: [ClipKind: (clip: Clip<ImageSequence>, source: Substring?, destination: Substring?, isTransitional: Bool)] = [:]
        var outroClips: [(clip: Clip<ImageSequence>, destination: Substring?)] = []
        var animations = [AnimationContext]()
        var index = files.startIndex
        while index < files.endIndex {
            let fileName = files[index].deletingPathExtension().lastPathComponent
            let sequenceNamePrefix = ParsedFileName.extractImageSequenceNamePrefix(fileName: fileName)
            let endIndexOfClip = files[index...].findFirstUnmatch {
                $0.lastPathComponent.range(of: "\(sequenceNamePrefix)\\d{6}.heic", options: .regularExpression) != nil
            }
            let imageSequence = ImageSequence(prefix: String(sequenceNamePrefix),
                                              lastFile: UInt8(endIndexOfClip - index - 1),
                                              baseURL: files[index].deletingLastPathComponent())
            let parsedName = ParsedFileName.from(fileName: fileName)
            let clip = Clip.from(parsedName: parsedName, sourceFile: imageSequence)
            if clip.intro != nil {
                introClips[clip.kind] = (clip, parsedName.from, parsedName.to, parsedName.from != nil || parsedName.isHideOrReveal)
            } else if clip.loop != nil { // there must be an intro if there is a loop, and since it's sorted, the intro comes first
                if introClips[clip.kind]?.clip.tryMerge(clip) != true {
                    Log.fault("failed to merge intro and loop clip of \(resourceName)")
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
        // If the intro clip has source, then we do not list it as a separate animation
        if outroClips.isEmpty || (!introClips.isEmpty && outroClips.allSatisfy { $0.destination != nil }) {
            for introClip in introClips.values {
                if outroClips.isEmpty || !introClip.isTransitional {
                    animations.append((Animation(clip: introClip.clip), introClip.source, introClip.destination))
                }
            }
        }
        for (outroClip, destination) in outroClips {
            if var clip = introClips[outroClip.kind], clip.clip.tryMerge(outroClip) {
                animations.append((Animation(clip: clip.clip), clip.source, destination))
            } else if introClips[outroClip.kind] == nil {
                animations.append((Animation(clip: outroClip), nil, destination))
            } else {
                Log.fault("failed to merge intro and outro clip of \(resourceName)")
            }
        }
        return animations
    }
    
    private static func createJumpGraph(context: [AnimationContext]) -> JumpGraph {
        var nameToAnimations = [String: [Animation]]()
        for c in context {
            nameToAnimations.setDefault([], forKey: c.animation.name) { animations in
                animations.append(c.animation)
            }
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

struct FileSortComparator: SortComparator {
    var order: SortOrder = .forward
    
    func compare(_ lhs: URL, _ rhs: URL) -> ComparisonResult {
        let lhsName = lhs.lastPathComponent
        let lhsKey = lhsName[lhsName.index(lhsName.startIndex, offsetBy: 3)...]
        let rhsName = rhs.lastPathComponent
        let rhsKey = rhsName[rhsName.index(rhsName.startIndex, offsetBy: 3)...]
        if lhsKey == rhsKey {
            return .orderedSame
        } else if lhsKey < rhsKey {
            return .orderedAscending
        } else {
            return .orderedDescending
        }
    }
}

enum ClipKind: Int, Hashable {
    case normal = -1
    case mask = 0
    case outline = 1
    
    init(isMask: Bool, isOutline: Bool) {
        switch (isMask, isOutline) {
        case (false, false): self = .normal
        case (false, true): self = .outline
        case (true, false): self = .mask
        case (true, true): Log.fault("unexpected file name with both Mask and Outline keywords")
        }
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
struct Clip<MediaType: Sendable> {
    let name: String
    let kind: ClipKind

    private(set) var intro: MediaType?
    private(set) var loop: MediaType?
    private(set) var outro: MediaType?
    
    init(name: String, kind: ClipKind = .normal, intro: MediaType? = nil, loop: MediaType? = nil, outro: MediaType? = nil) {
        self.name = name
        self.kind = kind
        self.intro = intro
        self.loop = loop
        self.outro = outro
    }
    
    fileprivate static func from(parsedName: ParsedFileName, sourceFile: MediaType) -> Self {
        var clip = Clip(
            name: String(parsedName.resourceName),
            kind: ClipKind(isMask: parsedName.isMask, isOutline: parsedName.isOutline)
        )
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
        #if DEBUG
        guard name == other.name else {
            Log.fault("Cannot merge clips with different names: want \(name), got \(other.name)")
        }
        #endif
        if (intro != nil && other.intro != nil)
            || (outro != nil && other.outro != nil)
            || (loop != nil && other.loop != nil)
            || (kind != other.kind)
        {
            return false
        }
        intro = intro ?? other.intro
        loop = loop ?? other.loop
        outro = outro ?? other.outro
        return true
    }
}

extension Clip: Equatable where MediaType: Equatable {
    static func == (this: Clip<MediaType>, other: Clip<MediaType>) -> Bool {
        this.name == other.name && this.kind == other.kind
            && this.intro == other.intro && this.loop == other.loop && this.outro == other.outro
    }
}

extension Clip: Hashable where MediaType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(kind)
        hasher.combine(intro)
        hasher.combine(loop)
        hasher.combine(outro)
    }
}

/// ImageSequence files are a series of heic images that can be played one by one to form an animation.
struct ImageSequence: Equatable, Hashable {
    /// prefix is the file name template missing the index number.
    ///
    /// It must starts with 3 digits, then has an underscore followed by some alphabetic characters,
    /// then it ends with another underscore.
    ///
    /// Specifically, it is the prefix of a file name without extension or indexing number.
    ///
    /// For example, *"000\_Background\_"*.
    ///
    /// The full file name can be reconstructed through `String(format: "\(prefix)%06d.heic", number)`.
    /// *Note*: the reconstructed file name does not include the extension.
    let prefix: String
    let lastFile: UInt8
    let baseURL: URL
    
    private func fileNameWithExtension(at index: UInt8) -> String {
        String(format: "\(prefix)%06d.heic", index)
    }
    
    /// urls returns
    var urls: [URL] {
        (0 ... lastFile)
            .lazy
            .map { self.fileNameWithExtension(at: $0) }
            .map { self.baseURL.appendingPathComponent($0) }
    }
}
