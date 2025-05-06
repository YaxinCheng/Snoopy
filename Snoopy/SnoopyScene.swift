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
    .systemGreen,
    .systemBlue,
    .systemPink,
    .systemYellow,
    .systemCyan,
    .systemGray,
    .systemMint,
    .systemIndigo,
    .systemOrange,
    .systemPurple,
    .cyan,
    .black
]
private let LOOP_REPEAT_LIMIT: UInt = 8
private let IMAGES_SEQ_INTERVAL: TimeInterval = 0.06
private let MASK_INTERVAL: TimeInterval = 0.03

@MainActor
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

    private lazy var keyValueObservers: [Any?] = {
        var observers = [Any?]()
        observers.reserveCapacity(2)
        return observers
    }()

    /// videoDidFinishPlayingObserver observes when video has finished playing.
    private var videoDidFinishPlayingObserver: AnyCancellable? {
        willSet {
            videoDidFinishPlayingObserver?.cancel()
        }
    }

    /// imageSequenceTimer is a timer used to update image sequences.
    private var imageSequenceTimer: AnyCancellable!
    /// maskTimer is a timer used to update mask image sequences.
    private var maskTimer: AnyCancellable!

    /// setupBackgroundAndSnoopyHouse is a once token that executes a given function only once per program run.
    private let setupBackgroundAndSnoopyHouse = Once(label: "com.snoopy.setupBackgroundAndSnoopyHouse")

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
            imageSequenceTimer = Timer.publish(every: IMAGES_SEQ_INTERVAL, on: .main, in: .default).autoconnect().sink { _ in
                Task { @MainActor [weak self] in
                    self?.updateImageSequence()
                }
            }
            maskTimer = Timer.publish(every: MASK_INTERVAL, on: .main, in: .default).autoconnect().sink { _ in
                Task { @MainActor [weak self] in
                    self?.updateMask()
                }
            }

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
            keyValueObservers.append(introTransition.last?.waitForItemReady { _ in
                let transitionTime = introTransition.map(\.duration).reduce(CMTime.zero, CMTimeAdd)
                Task { @MainActor [weak self] in
                    self?.setupMask(player: player, atTime: transitionTime, mask: mask.mask.intro!, outline: mask.outline.intro!)
                }
            })
            keyValueObservers.append(playItems.last?.waitForItemReady { item in
                let maskTime = CMTimeMakeWithSeconds(Double(mask.mask.outro?.urls.count ?? 0) * 1.5 * MASK_INTERVAL, preferredTimescale: 600)
                Task { @MainActor [weak self] in
                    self?.setupMask(player: player, atTime: CMTimeSubtract(item.duration, maskTime), mask: mask.mask.outro!, outline: mask.outline.outro!)
                }
            })
        } else {
            keyValueObservers.removeAll(keepingCapacity: true)
        }

        videoDidFinishPlayingObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: totalPlayItems.last).sink { _ in
            Task { @MainActor [weak self] in
                self?.videoDidFinishPlaying()
            }
        }
    }

    private func setupMask(player: AVPlayer, atTime insertTime: CMTime, mask: ImageSequence, outline: ImageSequence) {
        // observer needs to be removed after triggering,
        // or it will trigger the block multiple times.
        var observer: Any?
        observer = player.addBoundaryTimeObserver(forTimes: [NSValue(time: insertTime)], queue: .global()) {
            Log.debug("AVPlayer boundary observer triggered at time \(insertTime.seconds) secs")
            if let observer = observer {
                player.removeTimeObserver(observer)
            }
            DispatchQueue.main.async { [weak self] in
                self?.cropNode.maskNode = AnimatedImageNode(contentsOf: mask.urls).fullscreen(in: self)
                self?.outlineNode.reset(contentsOf: outline.urls).fullscreen(in: self)
            }
        }
    }

    private func setUpSceneFromImageSequenceClip(_ clip: Clip<ImageSequence>, decorations: [Animation]) {
        imageNode = AnimatedImageNode(contentsOf: expandUrls(from: clip)).fullscreen(in: self)
        addChild(imageNode!)

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

    private func updateImageSequence() {
        if let imageNode = imageNode, imageNode.update() {
            Log.info("image sequence animation finished playing")
            _didFinishPlaying.send()
        }
    }

    private func updateMask() {
        if let maskNode = cropNode.maskNode as? AnimatedImageNode {
            let maskFinished = maskNode.update()
            let outlineFinished = outlineNode.update()
            if maskFinished && outlineFinished {
                Log.info("mask and outline finished playing")
                cropNode.maskNode = nil
                outlineNode = .clear
            }
        }
    }

    private func videoDidFinishPlaying() {
        Log.info("video animation finished playing")
        _didFinishPlaying.send()
    }
}
