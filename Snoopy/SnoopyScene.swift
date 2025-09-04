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
private let LOOP_REPEAT_LIMIT: UInt = 8
private let IMAGES_SEQ_INTERVAL: TimeInterval = 0.06
private let MASK_INTERVAL: TimeInterval = 0.06
private let TOP_Z_PRIORITY: CGFloat = 11
private let SECONDARY_Z_PRIORITY: CGFloat = 10

final class SnoopyScene: SKScene {
    /// imageNode is the node for image sequence animations.
    private var imageNode: AnimatedImageNode? {
        willSet {
            imageNode?.removeFromParent()
        }
    }

    /// videoNode is the node for video animations.
    private var videoNode: SKVideoNode? {
        willSet {
            videoNode?.removeFromParent()
        }
    }

    /// videoDidFinishPlayingObserver observes when video has finished playing.
    private var videoDidFinishPlayingObserver: AnyCancellable? {
        willSet {
            videoDidFinishPlayingObserver?.cancel()
        }
    }

    /// decorationDidFinishPlayingObserver observes if the decoration video has finished playing.
    private var decorationDidFinishPlayingObserver: AnyCancellable? {
        willSet {
            decorationDidFinishPlayingObserver?.cancel()
        }
    }

    /// setupBackgroundAndSnoopyHouse is a once token that executes a given function only once per program run.
    private lazy var setupBackgroundAndSnoopyHouse = AsyncOnce()

    private let _didFinishPlaying = PassthroughSubject<Void, Never>()

    /// didFinishPlaying is a publisher that sends a value when the image sequence / video animation finished playing.
    /// This is exposed to the outside world so they can react to the event when animation playing is finished.
    var didFinishPlaying: AnyPublisher<Void, Never> {
        _didFinishPlaying.eraseToAnyPublisher()
    }

    /// setup function sets up an animation with given resources.
    func setup(animation: Animation, backgroundColor: NSColor, background: URL?, snoopyHouse: URL, mask: Mask?, transition: Clip<URL>?, decoration: Animation?) async {
        await setupBackgroundAndSnoopyHouse.execute {
            do {
                async let setupColor = setupColorBackgroundNode(color: backgroundColor)
                async let setupBackground = setupBackground(background)
                async let setupSnoopyHouse = setupSnoopyHouse(snoopyHouse)
                let (colorNode, backgroundNode, houseNode) = try await (
                    setupColor,
                    setupBackground,
                    setupSnoopyHouse,
                )
                await MainActor.run {
                    addChild(colorNode)
                    if let backgroundNode = backgroundNode {
                        addChild(backgroundNode)
                    }
                    addChild(houseNode)
                }
            } catch {
                Log.fault("Unable to load initial resources: \(error)")
            }
        }

        cleanup()
        switch animation {
        case .video(let clip):
            if ParsedFileName.isDream(clip.name) {
                await setupSceneFromDreamVideoClip(clip, mask: mask!, transition: transition!)
            } else {
                await setupSceneFromPureVideoClip(clip)
            }
        case .imageSequence(let clip):
            await setUpSceneFromImageSequenceClip(clip, decoration: decoration)
        }
    }

    private func setupColorBackgroundNode(color: NSColor) -> some SKNode {
        return SKSpriteNode(color: color, size: size).fullscreen(in: self)
    }

    private func setupBackground(_ background: URL?) async throws -> SKSpriteNode? {
        guard let background = background else { return nil }
        let texture = try await SKTexture.asyncFrom(contentsOf: background)
        let backgroundNode = SKSpriteNode(texture: texture).fullscreen(in: self)
        backgroundNode.blendMode = .alpha
        return backgroundNode
    }

    private func setupSnoopyHouse(_ house: URL) async throws -> some SKNode {
        let texture = try await SKTexture.asyncFrom(contentsOf: house)
        let houseNode = SKSpriteNode(texture: texture)
        houseNode.size = CGSize(width: size.width * HOUSE_SCALE, height: size.height * HOUSE_SCALE)
        houseNode.position = CGPoint(x: size.width / 2, y: size.height / 2 - HOUSE_Y_OFFSET)
        return houseNode
    }

    /// setupSceneFromPureVideoClip sets up the scene for non-dreaming video clips.
    private func setupSceneFromPureVideoClip(_ clip: Clip<URL>) async {
        let playItems = await Batch.asyncLoad(urls: Self.expandUrls(from: clip), transform: AVPlayerItem.load(url:))
        let player = AVQueuePlayer(items: playItems)
        let videoNode = SKVideoNode(avPlayer: player).fullscreen(in: self)
        addChild(videoNode)
        self.videoNode = videoNode

        videoDidFinishPlayingObserver = NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: playItems.last).sink { [weak self] _ in
            Log.info("video animation finished playing: \(playItems.last!)")
            self?._didFinishPlaying.send()
        }

        await playItems.first?.ready()
        await Self.forceLoadingFirstFrame(player: player)
        imageNode = nil
        videoNode.play()
    }

    /// setupSceneFromDreamVideoClip sets up the scene for dreaming video clips.
    private func setupSceneFromDreamVideoClip(_ clip: Clip<URL>, mask: Mask, transition: Clip<URL>) async {
        async let transitionPlayerLoad = setupTransitionPlayerAndItems(transition: transition)
        async let dreamPlayerLoad = setupDreamPlayerAndItems(clip: clip)
        let ((transitionPlayer, introTransition, outroTransition), (dreamPlayer, playItems)) = await (
            transitionPlayerLoad, dreamPlayerLoad
        )
        let transitionVideoNode = SKVideoNode(avPlayer: transitionPlayer).fullscreen(in: self)
        addChild(transitionVideoNode)
        videoNode = transitionVideoNode

        let dreamVideoNode = MaskedVideoNode(videoNode:
            SKVideoNode(avPlayer: dreamPlayer).fullscreen(in: self))
        dreamVideoNode.isHidden = true
        dreamVideoNode.zPosition = TOP_Z_PRIORITY
        addChild(dreamVideoNode)

        let outroMaskCache = MaskCache(mask: mask.mask.outro!, outline: mask.outline.outro!)
        var introMaskCache: MaskCache?
        if !introTransition.isEmpty { // has intro transition
            introMaskCache = MaskCache(mask: mask.mask.intro!, outline: mask.outline.intro!)

            await introTransition.first?.ready()
            await Self.forceLoadingFirstFrame(player: transitionPlayer)
            imageNode = nil
            transitionVideoNode.play()
        } else { // no intro, direct to dream
            dreamVideoNode.unhideAndPlay()
        }

        videoDidFinishPlayingObserver = NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: nil).sink {
            [weak self, weak transitionPlayer, weak transitionVideoNode, weak dreamVideoNode] notification in
            guard let item = notification.object as? AVPlayerItem else { return }
            if item === outroTransition.last {
                Log.info("video animation finished playing: \(item)")
                self?._didFinishPlaying.send()
            } else if item === introTransition.last {
                Task {
                    dreamVideoNode?.isHidden = false
                    if dreamVideoNode != nil {
                        await self?.playMask(cropNode: dreamVideoNode!, maskCache: introMaskCache!)
                    }
                    dreamVideoNode?.play()
                    transitionPlayer?.advanceToNextItem()
                }
            } else if item === playItems.last {
                Task {
                    if dreamVideoNode != nil {
                        await self?.playMask(cropNode: dreamVideoNode!, maskCache: outroMaskCache)
                    }
                    dreamVideoNode?.removeFromParent()
                    transitionVideoNode?.play()
                }
            }
        }
    }

    private func setupTransitionPlayerAndItems(transition: Clip<URL>) async -> (player: AVQueuePlayer, introTransition: [AVPlayerItem], outroTransition: [AVPlayerItem]) {
        async let introTransitionLoad = OptionalToArray(transition.intro.asyncMap(AVPlayerItem.load(url:)))
        async let outroTransitionLoad = OptionalToArray(transition.outro.asyncMap(AVPlayerItem.load(url:)))
        let (introTransition, outroTransition) = await (introTransitionLoad, outroTransitionLoad)
        let player = AVQueuePlayer(items: introTransition + outroTransition)
        player.actionAtItemEnd = .pause
        return (player, introTransition, outroTransition)
    }

    private func setupDreamPlayerAndItems(clip: Clip<URL>) async -> (player: AVQueuePlayer, items: [AVPlayerItem]) {
        let playItems = await Batch.asyncLoad(urls: Self.expandUrls(from: clip), transform: AVPlayerItem.load(url:))
        let player = AVQueuePlayer(items: playItems)
        return (player, playItems)
    }

    private func playMask(cropNode: some SKCropNode, maskCache: MaskCache) async {
        Log.info("setting up mask and outline")
        cropNode.maskNode = maskCache.maskNode.fullscreen(in: self)
        let outlineNode = maskCache.outlineNode.fullscreen(in: self)
        addChild(outlineNode)
        async let playMask: ()? = (cropNode.maskNode as? AnimatedImageNode)?.play(timePerFrame: MASK_INTERVAL)
        async let playOutline: () = outlineNode.play(timePerFrame: MASK_INTERVAL)
        Log.info("mask and outline started playing")
        _ = await (playMask, playOutline)
        Log.info("mask and outline finished playing")
        cropNode.maskNode = nil
        outlineNode.removeFromParent()
    }

    private func setUpSceneFromImageSequenceClip(_ clip: Clip<ImageSequence>, decoration: Animation?) async {
        async let imageNodeLoad = AnimatedImageNode.asyncCreate(contentsOf: Self.expandUrls(from: clip)).fullscreen(in: self)
        let decorationURLs = decoration.map { Self.expandUrls(from: $0.unwrapToVideo()) }
        async let decorationItemsLoad = Batch.asyncLoad(urls: decorationURLs ?? [], transform: AVPlayerItem.load(url:))
        let (imageNode, decorationItems) = await (imageNodeLoad, decorationItemsLoad)
        addChild(imageNode)
        self.imageNode = imageNode
        videoNode = nil
        var decorationNode: SKVideoNode?
        Task { [weak self, weak decorationNode] in
            await self?.imageNode?.play(timePerFrame: IMAGES_SEQ_INTERVAL)
            decorationNode?.removeFromParent()
            self?._didFinishPlaying.send()
        }

        if !decorationItems.isEmpty {
            Log.debug("decoration triggered: \(decoration!.name)")
            decorationNode = SKVideoNode(avPlayer: AVQueuePlayer(items: decorationItems)).fullscreen(in: self)
            addChild(decorationNode!)
            decorationNode?.zPosition = SECONDARY_Z_PRIORITY
            decorationNode?.play()
            decorationDidFinishPlayingObserver = NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: decorationItems.last).sink { [weak self, weak decorationNode] _ in
                decorationNode?.removeFromParent()
                self?.decorationDidFinishPlayingObserver = nil
            }
        }
    }

    private static func expandUrls(from videoClip: Clip<URL>) -> [URL] {
        var result = OptionalToArray(videoClip.intro)
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(videoClip.loop).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(videoClip.outro))
        return result
    }

    private static func expandUrls(from imageSequenceClip: Clip<ImageSequence>) -> [URL] {
        var result = OptionalToArray(imageSequenceClip.intro?.urls)
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(imageSequenceClip.loop?.urls).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(imageSequenceClip.outro?.urls))
        return result
    }

    private func cleanup() {
        videoDidFinishPlayingObserver = nil
    }

    /// forceLoadingFirstFrame is a function that forces player to load the first frame and wait for it.
    /// This is used to fix the flickering issue.
    private static func forceLoadingFirstFrame(player: AVPlayer) async {
        await player.seek(to: .zero)
    }
}

@MainActor
final class MaskCache {
    private let maskSource: [URL]
    private let outlineSource: [URL]
    private var _maskNode: AnimatedImageNode?
    private var _outlineNode: AnimatedImageNode?

    init(mask: ImageSequence, outline: ImageSequence) {
        self.maskSource = mask.urls
        self.outlineSource = outline.urls
        Task.detached {
            async let maskNodeLoad = AnimatedImageNode.asyncCreate(contentsOf: mask.urls)
            async let outlineNodeLoad = AnimatedImageNode.asyncCreate(contentsOf: outline.urls)
            let (maskNode, outlineNode) = await (maskNodeLoad, outlineNodeLoad)
            await MainActor.run { [weak self] in
                self?._maskNode = maskNode
                self?._outlineNode = outlineNode
            }
        }
    }

    var maskNode: AnimatedImageNode {
        if _maskNode == nil {
            Log.notice("_maskNode was read before being loaded")
            _maskNode = AnimatedImageNode(contentsOf: maskSource)
        }
        return _maskNode!
    }

    var outlineNode: AnimatedImageNode {
        if _outlineNode == nil {
            Log.notice("_outlineNode was read before being loaded")
            _outlineNode = AnimatedImageNode(contentsOf: outlineSource)
        }
        return _outlineNode!
    }
}
