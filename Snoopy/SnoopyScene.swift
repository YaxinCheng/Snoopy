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
private let LOOP_REPEAT_LIMIT: UInt = 5
private let IMAGES_SEQ_INTERVAL: TimeInterval = 0.06
private let MASK_INTERVAL: TimeInterval = 0.03
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

    /// decorationNode is the node for decoration animations.
    private var decorationNode: SKVideoNode? {
        willSet {
            decorationNode?.removeFromParent()
        }
    }

    /// setupBackgroundAndSnoopyHouse is a once token that executes a given function only once per program run.
    private lazy var setupBackgroundAndSnoopyHouse = AsyncOnce()
    private var snoopyHouseVideoLoop: AVPlayerLooper?

    private let _didFinishPlaying = PassthroughSubject<Void, Never>()

    /// didFinishPlaying is a publisher that sends a value when the image sequence / video animation finished playing.
    /// This is exposed to the outside world so they can react to the event when animation playing is finished.
    var didFinishPlaying: AnyPublisher<Void, Never> {
        _didFinishPlaying.eraseToAnyPublisher()
    }

    /// setup function sets up an animation with given resources.
    func setup(animation: Animation, backgroundColor: NSColor, background: URL?, snoopyHouse: URL, mask: Mask?, transition: Clip<URL>?, decoration: Animation?, specialConnection: Clip<ImageSequence>?) async {
        await setupBackgroundAndHouse(backgroundColor: backgroundColor, background: background, snoopyHouse: snoopyHouse)
        cleanup()
        switch animation {
        case .video(let clip):
            if NameUtil.isDream(clip.name) {
                await setupSceneFromDreamVideoClip(clip, mask: mask!, transition: transition!, specialConnection: specialConnection)
            } else {
                await setupSceneFromPureVideoClip(clip)
            }
        case .imageSequence(let clip):
            await setUpSceneFromImageSequenceClip(clip, decoration: decoration)
        }
    }

    func setupBackgroundAndHouse(backgroundColor: NSColor, background: URL?, snoopyHouse: URL) async {
        await setupBackgroundAndSnoopyHouse.execute { [weak self] in
            guard let self else { return }
            do {
                async let setupColor = self.setupColorBackgroundNode(color: backgroundColor)
                async let setupBackground = self.setupBackground(background)
                async let setupSnoopyHouse = self.setupSnoopyHouse(snoopyHouse)
                let (colorNode, backgroundNode, houseNode) = try await (
                    setupColor,
                    setupBackground,
                    setupSnoopyHouse
                )
                await MainActor.run {
                    self.addChild(colorNode)
                    if let backgroundNode = backgroundNode {
                        self.addChild(backgroundNode)
                    }
                    self.addChild(houseNode)
                    (houseNode as? SKVideoNode)?.play()
                }
            } catch {
                Log.fault("Unable to load initial resources: \(error)")
            }
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

    private func setupSnoopyHouse(_ house: URL) async throws -> SKNode {
        let houseNode = switch house.pathExtension {
        case "heic": try await setupImageSnoopyHouse(house)
        case "mov": try await setupVideoSnoopyHouse(house)
        default: Log.fault("Unexpected snoopy house type: \(house)")
        }
        houseNode.position = CGPoint(x: size.width / 2, y: size.height / 2 - HOUSE_Y_OFFSET)
        return houseNode
    }

    private func setupImageSnoopyHouse(_ house: URL) async throws -> some SKNode {
        let texture = try await SKTexture.asyncFrom(contentsOf: house)
        let houseNode = SKSpriteNode(texture: texture)
        houseNode.size = CGSize(width: size.width * HOUSE_SCALE, height: size.height * HOUSE_SCALE)
        return houseNode
    }

    private func setupVideoSnoopyHouse(_ house: URL) async throws -> some SKNode {
        let playItem = await AVPlayerItem.load(url: house)
        let player = AVQueuePlayer()
        snoopyHouseVideoLoop = AVPlayerLooper(player: player, templateItem: playItem)

        let houseNode = SKVideoNode(avPlayer: player)
        houseNode.size = CGSize(width: size.width * HOUSE_SCALE, height: size.height * HOUSE_SCALE)
        return houseNode
    }

    /// setupSceneFromPureVideoClip sets up the scene for non-dreaming video clips.
    private func setupSceneFromPureVideoClip(_ clip: Clip<URL>) async {
        let playItems = await Batch.asyncLoad(urls: Self.expandUrls(from: clip), transform: AVPlayerItem.load(url:))
        let player = AVQueuePlayer(items: playItems)
        await playItems.first?.ready()

        let videoNode = SKVideoNode(avPlayer: player).fullscreen(in: self)
        addChild(videoNode)
        videoDidFinishPlayingObserver = NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: playItems.last).sink { [weak self] _ in
            Log.info("video animation finished playing: \(playItems.last!)")
            self?._didFinishPlaying.send()
        }

        await startPlaybackAndWaitForFirstFrame(videoNode: videoNode, player: player)
        self.videoNode = videoNode
        imageNode = nil
    }

    /// setupSceneFromDreamVideoClip sets up the scene for dreaming video clips.
    private func setupSceneFromDreamVideoClip(_ clip: Clip<URL>, mask: Mask, transition: Clip<URL>, specialConnection: Clip<ImageSequence>?) async {
        async let transitionPlayerLoad = setupTransitionPlayerAndItems(transition: transition)
        async let dreamPlayerLoad = setupDreamPlayerAndItems(clip: clip)
        async let specialConnectionNodeLoad: AnimatedImageNode? = if let specialConnection {
            await AnimatedImageNode
                .asyncCreate(contentsOf: Self.expandUrls(from: specialConnection))
                .fullscreen(in: self)
        } else {
            nil
        }
        let ((transitionPlayer, introTransition, outroTransition), (dreamPlayer, playItems), specialConnectionNode) = await (
            transitionPlayerLoad, dreamPlayerLoad, specialConnectionNodeLoad
        )
        let transitionVideoNode = SKVideoNode(avPlayer: transitionPlayer).fullscreen(in: self)
        addChild(transitionVideoNode)

        if let specialConnectionNode {
            specialConnectionNode.isHidden = true
            specialConnectionNode.zPosition = TOP_Z_PRIORITY
            addChild(specialConnectionNode)
        }

        let dreamVideoNode = MaskedVideoNode(videoNode:
            SKVideoNode(avPlayer: dreamPlayer).fullscreen(in: self))
        dreamVideoNode.isHidden = true
        dreamVideoNode.zPosition = TOP_Z_PRIORITY
        addChild(dreamVideoNode)

        let outroMaskCache = MaskCache(mask: mask.mask.outro!, outline: mask.outline.outro!)
        var introMaskCache: MaskCache?
        if !introTransition.isEmpty { // has intro transition
            if specialConnectionNode == nil {
                introMaskCache = MaskCache(mask: mask.mask.intro!, outline: mask.outline.intro!)
            }
            await startPlaybackAndWaitForFirstFrame(videoNode: transitionVideoNode, player: transitionPlayer)
            videoNode = transitionVideoNode
            imageNode = nil
        } else { // no intro, direct to dream
            videoNode = transitionVideoNode
            dreamVideoNode.isHidden = false
            await startPlaybackAndWaitForFirstFrame(videoNode: dreamVideoNode, player: dreamPlayer)
            imageNode = nil
        }

        videoDidFinishPlayingObserver = NotificationCenter.default.publisher(
            for: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil
        ).sink { [weak self, weak transitionPlayer, weak transitionVideoNode, weak dreamVideoNode, weak dreamPlayer, weak specialConnectionNode] notification in
            guard let item = notification.object as? AVPlayerItem else { return }
            if item === outroTransition.last {
                Log.info("video animation finished playing: \(item)")
                self?._didFinishPlaying.send()
            } else if item === introTransition.last {
                Task {
                    transitionPlayer?.advanceToNextItem()
                    await outroTransition.first?.ready()

                    if let specialConnectionNode {
                        specialConnectionNode.isHidden = false
                        await specialConnectionNode.play(timePerFrame: IMAGES_SEQ_INTERVAL)
                        if let dreamVideoNode, let dreamPlayer {
                            dreamVideoNode.isHidden = false
                            await self?.startPlaybackAndWaitForFirstFrame(videoNode: dreamVideoNode, player: dreamPlayer)
                        }
                        specialConnectionNode.removeFromParent()
                    } else if let dreamVideoNode, let dreamPlayer {
                        await self?.startPlaybackAndWaitForFirstFrame(videoNode: dreamVideoNode, player: dreamPlayer)
                        dreamVideoNode.isHidden = false
                        if let introMaskCache {
                            await self?.playMask(cropNode: dreamVideoNode, maskCache: introMaskCache)
                        }
                    }
                }
            } else if item === playItems.last {
                Task {
                    if let transitionVideoNode, let transitionPlayer {
                        await self?.startPlaybackAndWaitForFirstFrame(videoNode: transitionVideoNode, player: transitionPlayer)
                    }
                    if let dreamVideoNode {
                        await self?.playMask(cropNode: dreamVideoNode, maskCache: outroMaskCache)
                        dreamVideoNode.removeFromParent()
                    }
                }
            }
        }
    }

    private func setupTransitionPlayerAndItems(transition: Clip<URL>) async -> (player: AVQueuePlayer, introTransition: [AVPlayerItem], outroTransition: [AVPlayerItem]) {
        async let introTransitionLoad = OptionalToArray(transition.intro.asyncMap(AVPlayerItem.load(url:)))
        async let outroTransitionLoad = OptionalToArray(transition.outro.asyncMap(AVPlayerItem.load(url:)))
        let (introTransition, outroTransition) = await (introTransitionLoad, outroTransitionLoad)
        let allItems = introTransition + outroTransition
        let player = AVQueuePlayer(items: allItems)
        player.actionAtItemEnd = .pause
        await allItems.first?.ready()
        return (player, introTransition, outroTransition)
    }

    private func setupDreamPlayerAndItems(clip: Clip<URL>) async -> (player: AVQueuePlayer, items: [AVPlayerItem]) {
        let playItems = await Batch.asyncLoad(urls: Self.expandUrls(from: clip), transform: AVPlayerItem.load(url:))
        let player = AVQueuePlayer(items: playItems)
        await playItems.first?.ready()
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
        let shouldLoadDecoration = (decorationNode == nil) && (decoration != nil)
        let decorationURLs = shouldLoadDecoration ? decoration.map { Self.expandUrls(from: $0.unwrapToVideo()) } : nil
        async let decorationItemsLoad = Batch.asyncLoad(urls: decorationURLs ?? [], transform: AVPlayerItem.load(url:))
        async let imageNodeLoad = AnimatedImageNode.asyncCreate(contentsOf: Self.expandUrls(from: clip)).fullscreen(in: self)
        let (imageNode, decorationItems) = await (imageNodeLoad, decorationItemsLoad)

        addChild(imageNode)
        self.imageNode = imageNode
        videoNode = nil

        if !decorationItems.isEmpty {
            Log.debug("decoration triggered: \(decoration!.name)")
            let player = AVQueuePlayer(items: decorationItems)
            await decorationItems.first?.ready()
            let node = SKVideoNode(avPlayer: player).fullscreen(in: self)
            node.zPosition = SECONDARY_Z_PRIORITY
            addChild(node)
            decorationNode = node

            decorationDidFinishPlayingObserver = NotificationCenter.default
                .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: decorationItems.last)
                .sink { [weak self] _ in
                    self?.decorationNode = nil
                    self?.decorationDidFinishPlayingObserver = nil
                }
            await startPlaybackAndWaitForFirstFrame(videoNode: node, player: player)
        }

        Task { [weak self] in
            await self?.imageNode?.play(timePerFrame: IMAGES_SEQ_INTERVAL)
            self?._didFinishPlaying.send()
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

    /// Prerolls the player, starts playback, and suspends until the first video frame
    /// has been rendered by SpriteKit before removing the previous node.
    private func startPlaybackAndWaitForFirstFrame(videoNode: SKVideoNode, player: AVPlayer) async {
        await player.currentItem?.ready()
        if player.status == .readyToPlay {
            _ = await player.preroll(atRate: 1.0)
        }
        videoNode.play()
        await Self.waitForPlaybackToAdvance(player: player)
        await run(SKAction.wait(forDuration: 2.0 / 60.0))
    }

    private func startPlaybackAndWaitForFirstFrame(videoNode: MaskedVideoNode, player: AVPlayer) async {
        await player.currentItem?.ready()
        if player.status == .readyToPlay {
            _ = await player.preroll(atRate: 1.0)
        }
        videoNode.play()
        await Self.waitForPlaybackToAdvance(player: player)
        await run(SKAction.wait(forDuration: 2.0 / 60.0))
    }

    /// Suspends until `player`'s media clock actually advances past `.zero` (or fails/times out).
    @MainActor
    private static func waitForPlaybackToAdvance(player: AVPlayer) async {
        guard let item = player.currentItem, item.status != .failed, player.status != .failed else {
            return
        }
        let minimumRenderedTime = CMTime(seconds: 0.08, preferredTimescale: 600)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            final class ObserverState: @unchecked Sendable {
                var token: Any?
                var resumed = false
            }
            let state = ObserverState()
            let interval = CMTime(value: 1, timescale: 120)

            state.token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
                guard !state.resumed else { return }
                let failed = player?.status == .failed || player?.currentItem?.status == .failed
                if time >= minimumRenderedTime || failed {
                    state.resumed = true
                    if let token = state.token {
                        player?.removeTimeObserver(token)
                        state.token = nil
                    }
                    continuation.resume()
                }
            }

            // Safety fallback in case an item cannot advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak player] in
                guard !state.resumed else { return }
                state.resumed = true
                if let token = state.token {
                    player?.removeTimeObserver(token)
                    state.token = nil
                }
                continuation.resume()
            }
        }
    }

    func stopDecoration() {
        decorationNode = nil
        decorationDidFinishPlayingObserver = nil
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
