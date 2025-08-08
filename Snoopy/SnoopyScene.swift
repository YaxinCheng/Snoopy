//
//  SnoopyScene.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-05-03.
//

import AVKit
import Combine
import SpriteKit

private let HOUSE_SCALE: CGFloat = 720 / 1080
private let HOUSE_Y_OFFSET: CGFloat = 180 / 1080
private let BACKGROUND_COLOURS: [NSColor] = [
    .systemBlue,
    .systemYellow,
    .systemCyan,
    .systemGray,
    .systemMint,
    .systemIndigo,
    .systemOrange,
    .systemPurple,
    .cyan,
]
private let LOOP_REPEAT_LIMIT: UInt = 8
private let IMAGES_SEQ_INTERVAL: TimeInterval = 0.06
private let MASK_INTERVAL: TimeInterval = 0.06

final class SnoopyScene: SKScene {
    /// cropNode is a node containing the SKVideoNode for video animations.
    /// We use cropNode to better and easier control the masks.
    private var cropNode = SKCropNode() {
        willSet {
            cropNode.removeAllChildren()
            cropNode.removeFromParent()
        }
    }

    /// outlineNode is the node displaying mask outlines.
    private var outlineNode: AnimatedImageNode = .clear {
        willSet {
            outlineNode.removeFromParent()
        }
    }

    /// imageNode is the node for image sequence animations.
    private var imageNode: AnimatedImageNode? = nil {
        willSet {
            imageNode?.removeFromParent()
        }
    }

    /// decorationNode displays the decoration resources when image sequence is playing.
    private var decorationNode: SKVideoNode? = nil {
        willSet {
            decorationNode?.removeFromParent()
        }
    }

    /// videoDidFinishPlayingObserver observes when video has finished playing.
    private var videoDidFinishPlayingObserver: AnyCancellable? {
        willSet {
            videoDidFinishPlayingObserver?.cancel()
        }
    }

    /// setupBackgroundAndSnoopyHouse is a once token that executes a given function only once per program run.
    private lazy var setupBackgroundAndSnoopyHouse = Once()

    private let _didFinishPlaying = PassthroughSubject<Void, Never>()

    /// didFinishPlaying is a publisher that sends a value when the image sequence / video animation finished playing.
    /// This is exposed to the outside world so they can react to the event when animation playing is finished.
    var didFinishPlaying: AnyPublisher<Void, Never> {
        _didFinishPlaying.eraseToAnyPublisher()
    }

    /// setup function sets up an animation with given resources.
    func setup(animation: Animation, background: URL?, snoopyHouses: [URL], mask: Mask?, transition: Clip<URL>?, decorations: [Animation]) {
        reset()
        let isFirstAnimation = children.isEmpty
        setupBackgroundAndSnoopyHouse.execute {
            setupBackground(background: background)
            setupSnoopyHouse(houses: snoopyHouses)
        }

        switch animation {
        case .video(let clip):
            setupSceneFromVideoClip(clip, isFirstAnimation: isFirstAnimation, mask: mask, transition: transition)
        case .imageSequence(let clip):
            setUpSceneFromImageSequenceClip(clip, decorations: decorations)
        }
    }

    private func reset() {
        cropNode.maskNode = nil
        cropNode.removeAllChildren()
        cropNode.removeFromParent()
        outlineNode = .clear
        outlineNode.removeFromParent()
        imageNode = nil
        decorationNode = nil
    }

    private func setupBackground(background: URL?) {
        let colorNode = SKSpriteNode(color: BACKGROUND_COLOURS.randomElement()!, size: size).fullscreen(in: self)
        addChild(colorNode)

        guard let background = background else { return }
        let backgroundNode = SKSpriteNode(texture: SKTexture(contentsOf: background)).fullscreen(in: self)
        backgroundNode.blendMode = .alpha
        addChild(backgroundNode)
    }

    private func setupSnoopyHouse(houses: [URL]) {
        let randomHouse = houses.randomElement()!
        let houseNode = SKSpriteNode(texture: SKTexture(contentsOf: randomHouse))
        houseNode.size = CGSize(width: size.width * HOUSE_SCALE, height: size.height * HOUSE_SCALE)
        houseNode.position = CGPoint(x: size.width / 2, y: size.height / 2 - HOUSE_Y_OFFSET)
        addChild(houseNode)
    }

    private func setupSceneFromVideoClip(_ clip: Clip<URL>, isFirstAnimation: Bool, mask: Mask?, transition: Clip<URL>?) {
        let videos = expandUrls(from: clip)
        let introTransition = isFirstAnimation ? [] : OptionalToArray(transition?.intro).map(AVPlayerItem.init(url:))
        let playItems = videos.map(AVPlayerItem.init(url:))
        let outroTransition = OptionalToArray(transition?.outro).map(AVPlayerItem.init(url:))
        let totalPlayItems = introTransition + playItems + outroTransition
        let player = AVQueuePlayer(items: totalPlayItems)
        let videoNode = SKVideoNode(avPlayer: player).fullscreen(in: self)
        cropNode.addChild(videoNode)
        addChild(outlineNode)
        addChild(cropNode)
        videoNode.play()
        if let mask = mask {
            if !isFirstAnimation {
                Task { [weak self] in
                    let introMaskCache = MaskCache(mask: mask.mask.intro!, outline: mask.outline.intro!)
                    guard let _ = await introTransition.last?.ready() else { return }
                    let transitionTime = introTransition.map(\.duration).reduce(CMTime.zero, CMTimeAdd)
                    await self?.setupMask(player: player, atTime: transitionTime, maskCache: introMaskCache)
                }
            }

            Task { [weak self] in
                let outroMaskCache = MaskCache(mask: mask.mask.outro!, outline: mask.outline.outro!)
                guard let item = await playItems.last?.ready() else { return }
                // magic number 2: it makes sure the play time for the mask is correct.
                // Without it, it will be played too early.
                let maskTime = CMTimeMakeWithSeconds((Double(mask.mask.outro?.urls.count ?? 0) - 2) * MASK_INTERVAL, preferredTimescale: 600)
                await self?.setupMask(player: player, atTime: CMTimeSubtract(item.duration, maskTime), maskCache: outroMaskCache)
            }
        }
        videoDidFinishPlayingObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: totalPlayItems.last).sink { [weak self] notification in
            self?.videoDidFinishPlaying(video: notification.object as! AVPlayerItem)
        }
    }

    @MainActor
    private func setupMask(player: AVPlayer, atTime insertTime: CMTime, maskCache: MaskCache) async {
        await player.waitUntil(forTimes: [NSValue(time: insertTime)])
        Log.info("setting up mask and outline")
        cropNode.maskNode = maskCache.maskNode.fullscreen(in: self)
        outlineNode.reset(textures: maskCache.outlineTextures).fullscreen(in: self)
        await withTaskGroup { group in
            group.addTask {
                await (self.cropNode.maskNode as? AnimatedImageNode)?.play(timePerFrame: MASK_INTERVAL)
            }
            group.addTask {
                await self.outlineNode.play(timePerFrame: MASK_INTERVAL)
            }
        }
        Log.info("mask and outline finished playing")
        cropNode.maskNode = nil
        outlineNode = .clear
    }

    private func setUpSceneFromImageSequenceClip(_ clip: Clip<ImageSequence>, decorations: [Animation]) {
        imageNode = AnimatedImageNode(contentsOf: expandUrls(from: clip)).fullscreen(in: self)
        addChild(imageNode!)
        Task { [weak self] in
            await self?.imageNode?.play(timePerFrame: IMAGES_SEQ_INTERVAL)
            Log.info("image sequence \"\(clip.name)\" animation finished playing")
            self?._didFinishPlaying.send()
        }

        let shouldHaveDecoration = (0 ..< 10).randomElement()! >= 7 // only show decoration 30% of the time.
        if shouldHaveDecoration, let decoration = decorations.randomElement() {
            Log.debug("decoration triggered: \(decoration.name)")
            let decoItems = expandUrls(from: decoration.unwrapToVideo()).map(AVPlayerItem.init(url:))
            decorationNode = SKVideoNode(avPlayer: AVQueuePlayer(items: decoItems)).fullscreen(in: self)
            addChild(decorationNode!)
            decorationNode?.play()
        }
    }

    private func expandUrls(from videoClip: Clip<URL>) -> [URL] {
        var result = OptionalToArray(videoClip.intro)
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(videoClip.loop).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(videoClip.outro))
        return result
    }

    private func expandUrls(from imageSequenceClip: Clip<ImageSequence>) -> [URL] {
        var result = OptionalToArray(imageSequenceClip.intro?.urls)
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(imageSequenceClip.loop?.urls).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(imageSequenceClip.outro?.urls))
        return result
    }

    private func videoDidFinishPlaying(video: AVPlayerItem) {
        Log.info("video animation finished playing: \(video)")
        _didFinishPlaying.send()
    }
}

@MainActor
final class MaskCache {
    private let maskSource: [URL]
    private let outlineSource: [URL]
    private var _maskNode: AnimatedImageNode?
    private var _outlineTexture: [SKTexture]?

    init(mask: ImageSequence, outline: ImageSequence) {
        maskSource = mask.urls
        outlineSource = outline.urls
        Task.detached { [weak self] in
            guard let cache = self else { return }
            let (maskTextureData, outlineTextureData) = await (
                Batch.asyncLoad(urls: cache.maskSource) { try! Data(contentsOf: $0) },
                Batch.asyncLoad(urls: cache.outlineSource) { try! Data(contentsOf: $0) }
            )
            let maskNode = await AnimatedImageNode(textures: maskTextureData.map(SKTexture.mustCreateFrom(imageData:)))
            let outlineTextures = outlineTextureData.map(SKTexture.mustCreateFrom(imageData:))
            Task { @MainActor in
                cache._maskNode = maskNode
                cache._outlineTexture = outlineTextures
            }
        }
    }

    var maskNode: AnimatedImageNode {
        if _maskNode == nil {
            _maskNode = AnimatedImageNode(contentsOf: maskSource)
        }
        return _maskNode!
    }

    var outlineTextures: [SKTexture] {
        if _outlineTexture == nil {
            _outlineTexture = Batch.syncLoad(urls: outlineSource, transform: SKTexture.mustCreateFrom(contentsOf:))
        }
        return _outlineTexture!
    }
}
