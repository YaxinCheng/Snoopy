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

final class SnoopyScene: SKScene {
    /// imageNode is the node for image sequence animations.
    private var imageNode: AnimatedImageNode? {
        willSet {
            imageNode?.removeFromParent()
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
                let (colorNode, backgroundNode, houseNode) = try await (
                    setupColorBackgroundNode(color: backgroundColor),
                    setupBackground(background),
                    setupSnoopyHouse(snoopyHouse),
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

        switch animation {
        case .video(let clip):
            setupSceneFromVideoClip(clip, mask: mask, transition: transition)
        case .imageSequence(let clip):
            setUpSceneFromImageSequenceClip(clip, decoration: decoration)
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

    private func setupSceneFromVideoClip(_ clip: Clip<URL>, mask: Mask?, transition: Clip<URL>?) {
        let introTransition = OptionalToArray(transition?.intro).map(AVPlayerItem.init(url:))
        let outroTransition = OptionalToArray(transition?.outro).map(AVPlayerItem.init(url:))
        let playItems = Self.expandUrls(from: clip).map(AVPlayerItem.init(url:))
        let hasTransition = !introTransition.isEmpty || !outroTransition.isEmpty
        let (mainPlayer, secondaryPlayer) = if hasTransition {
            (AVQueuePlayer(items: introTransition + outroTransition), AVQueuePlayer(items: playItems))
        } else {
            (AVQueuePlayer(items: playItems), AVQueuePlayer())
        }
        mainPlayer.actionAtItemEnd = .pause
        let mainVideoNode = SKVideoNode(avPlayer: mainPlayer).fullscreen(in: self)
        addChild(mainVideoNode)
        imageNode = nil

        if let mask = mask { // has transition and mask
            let secondaryVideoNode = MaskedVideoNode(videoNode: SKVideoNode(avPlayer: secondaryPlayer).fullscreen(in: self))
            addChild(secondaryVideoNode)
            secondaryVideoNode.isHidden = true

            if !introTransition.isEmpty { // has intro transition
                mainVideoNode.play()
                Task { [weak self] in
                    let introMaskCache = MaskCache(mask: mask.mask.intro!, outline: mask.outline.intro!)
                    guard let item = await introTransition.last?.ready() else { return }
                    let insertionTime = Self.calculateMaskInsertionTime(maskFrames: mask.mask.intro!.urlsCount, videoDuration: item.duration)
                    await mainPlayer.waitUntil(forTime: insertionTime)
                    secondaryVideoNode.isHidden = false
                    secondaryVideoNode.play()
                    await self?.playMask(cropNode: secondaryVideoNode, maskCache: introMaskCache)
                    mainPlayer.advanceToNextItem()
                }
            } else { // no intro, direct to dream
                secondaryVideoNode.isHidden = false
                secondaryVideoNode.play()
            }

            Task { [weak self] in
                let outroMaskCache = MaskCache(mask: mask.mask.outro!, outline: mask.outline.outro!)
                guard let item = await playItems.last?.ready() else { return }
                let insertionTime = Self.calculateMaskInsertionTime(maskFrames: mask.mask.outro!.urlsCount, videoDuration: item.duration)
                await secondaryPlayer.waitUntil(forTime: insertionTime)
                mainVideoNode.play()
                await self?.playMask(cropNode: secondaryVideoNode, maskCache: outroMaskCache)
                secondaryVideoNode.removeFromParent()
            }
        } else { // no transition
            mainVideoNode.play()
        }
        videoDidFinishPlayingObserver = NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: nil).sink { [weak self] notification in
            guard let item = notification.object as? AVPlayerItem else { return }
            if item === outroTransition.last || (!hasTransition && item === playItems.last) {
                Log.info("video animation finished playing: \(item)")
                self?._didFinishPlaying.send()
                mainVideoNode.removeFromParent()
            }
        }
    }

    private func setupIntroTransition(_ item: AVPlayerItem, mask: Mask, mainPlayer: AVQueuePlayer, secondaryVideoNode: MaskedVideoNode) async {
        let introMaskCache = MaskCache(mask: mask.mask.intro!, outline: mask.outline.intro!)
        _ = await item.ready()
        let insertionTime = Self.calculateMaskInsertionTime(maskFrames: mask.mask.intro!.urlsCount, videoDuration: item.duration)
        await mainPlayer.waitUntil(forTime: insertionTime)
        secondaryVideoNode.isHidden = false
        secondaryVideoNode.play()
        await playMask(cropNode: secondaryVideoNode, maskCache: introMaskCache)
        mainPlayer.advanceToNextItem()
    }

    private func setupOutroTransition(_ item: AVPlayerItem, mask: Mask, secondaryPlayer: AVQueuePlayer, mainVideoNode: SKVideoNode, secondaryVideoNode: some SKCropNode) async {
        let outroMaskCache = MaskCache(mask: mask.mask.outro!, outline: mask.outline.outro!)
        _ = await item.ready()
        let insertionTime = Self.calculateMaskInsertionTime(maskFrames: mask.mask.outro!.urlsCount, videoDuration: item.duration)
        await secondaryPlayer.waitUntil(forTime: insertionTime)
        mainVideoNode.play()
        await playMask(cropNode: secondaryVideoNode, maskCache: outroMaskCache)
        secondaryVideoNode.removeFromParent()
    }

    private static func calculateMaskInsertionTime(maskFrames: Int, videoDuration: CMTime) -> CMTime {
        let maskTime = CMTimeMakeWithSeconds(Double(maskFrames) * MASK_INTERVAL, preferredTimescale: 600)
        let insertionTime = CMTimeSubtract(videoDuration, maskTime)
        if insertionTime.seconds <= 0 {
            return videoDuration
        }
        return insertionTime
    }

    private func playMask(cropNode: some SKCropNode, maskCache: MaskCache) async {
        Log.info("setting up mask and outline")
        cropNode.maskNode = maskCache.maskNode.fullscreen(in: self)
        let outlineNode = AnimatedImageNode(textures: maskCache.outlineTextures).fullscreen(in: self)
        addChild(outlineNode)
        async let playMask: ()? = (cropNode.maskNode as? AnimatedImageNode)?.play(timePerFrame: MASK_INTERVAL)
        async let playOutline: () = outlineNode.play(timePerFrame: MASK_INTERVAL)
        Log.info("mask and outline started playing")
        _ = await (playMask, playOutline)
        Log.info("mask and outline finished playing")
        cropNode.maskNode = nil
        outlineNode.removeFromParent()
    }

    private func setUpSceneFromImageSequenceClip(_ clip: Clip<ImageSequence>, decoration: Animation?) {
        imageNode = AnimatedImageNode(contentsOf: Self.expandUrls(from: clip)).fullscreen(in: self)
        addChild(imageNode!)
        var decorationNode: SKVideoNode?
        Task {
            await imageNode?.play(timePerFrame: IMAGES_SEQ_INTERVAL)
            self._didFinishPlaying.send()
            decorationNode?.removeFromParent()
        }

        if let decoration = decoration {
            Log.debug("decoration triggered: \(decoration.name)")
            let decoItems = Self.expandUrls(from: decoration.unwrapToVideo()).map(AVPlayerItem.init(url:))
            decorationNode = SKVideoNode(avPlayer: AVQueuePlayer(items: decoItems)).fullscreen(in: self)
            addChild(decorationNode!)
            decorationNode?.play()
            decorationDidFinishPlayingObserver = NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: decoItems.last).sink { notification in
                if notification.object as? AVPlayerItem === decoItems.last {
                    decorationNode?.removeFromParent()
                }
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
}

@MainActor
final class MaskCache {
    private let maskSource: [URL]
    private let outlineSource: [URL]
    private var _maskNode: AnimatedImageNode?
    private var _outlineTexture: [SKTexture]?

    init(mask: ImageSequence, outline: ImageSequence) {
        let maskURLs = mask.urls
        maskSource = maskURLs
        let outlineURLs = outline.urls
        outlineSource = outlineURLs
        Task.detached {
            do {
                let (maskImages, outlineImages) = try await (
                    Batch.asyncLoad(urls: maskURLs) { try ImageRawData(contentsOf: $0) },
                    Batch.asyncLoad(urls: outlineURLs) { try ImageRawData(contentsOf: $0) }
                )
                await MainActor.run { [weak self] in
                    self?._maskNode = AnimatedImageNode(textures: maskImages.map { SKTexture(imageRawData: $0) })
                    self?._outlineTexture = outlineImages.map { SKTexture(imageRawData: $0) }
                }
            } catch {
                Log.error("failed to load mask / layout images: \(error)")
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

    var outlineTextures: [SKTexture] {
        if _outlineTexture == nil {
            Log.notice("_outlineTexture was read before being loaded")
            _outlineTexture = Batch.syncLoad(urls: outlineSource, transform: SKTexture.mustCreateFrom(contentsOf:))
        }
        return _outlineTexture!
    }
}
