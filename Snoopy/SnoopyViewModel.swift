//
//  SnoopyViewModel.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-02.
//

import AVKit
import Combine
import SpriteKit
import SwiftUI

private let LOOP_REPEAT_LIMIT: UInt = 3
private let IMAGES_SEQ_INTERVAL: TimeInterval = 0.06
private let MASK_INTERVAL: TimeInterval = 0.03
private let HOUSE_SCALE: CGFloat = 720 / 1080
private let HOUSE_Y_OFFSET: CGFloat = 180 / 1080

// TODO: Weather information.
final class SnoopyViewModel: ObservableObject {
    private static let resourceFiles =
        Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
    private let animations = AnimationCollection.from(files: resourceFiles)
    @Published var currentAnimation: Animation? {
        willSet {
            let needsMask = currentAnimation == nil || (newValue.map(\.name).map(ParsedFileName.isDream) ?? false)
            if needsMask {
                currentMask = animations.masks.randomElement()
                currentTransition = animations.dreamTransitions.randomElement()?.unwrapToVideo()
            } else {
                currentMask = nil
                currentTransition = nil
            }
            firstAnimation = currentAnimation == nil
        }
    }

    private var currentMask: Mask?
    private var currentTransition: Clip<URL>?

    @Published var didFinishPlaying: Bool = false
    private var firstAnimation = true

    private let backgroundColors: [NSColor] = [
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
    private var didSetupBackground = false
    private var didSetupHouse = false

    private var cropNode = SKCropNode() {
        willSet {
            cropNode.removeAllChildren()
            cropNode.removeFromParent()
        }
    }

    private var outlineNode: AnimatedImageNode = .clear {
        willSet {
            outlineNode.removeFromParent()
        }
    }

    private(set) var videoDidFinishPlaying = NotificationCenter.default.publisher(for: Notification.Name(rawValue: ""))
    private lazy var keyValueObservers: [Any?] = {
        var observers = [Any?]()
        observers.reserveCapacity(2)
        return observers
    }()

    private var imageNode: AnimatedImageNode? = nil {
        willSet {
            imageNode?.removeFromParent()
        }
    }

    let imageSequenceTimer = Timer.publish(every: IMAGES_SEQ_INTERVAL, on: .main, in: .common).autoconnect()
    let maskTimer = Timer.publish(every: MASK_INTERVAL, on: .main, in: .common).autoconnect()

    func setup(scene: SKScene) {
        if currentAnimation == nil {
            currentAnimation = randomDream()
        }
        reset()
        setupBackground(scene: scene, colors: backgroundColors, background: animations.background)
        setupSnoopyHouse(scene: scene, houses: animations.specialImages)
        switch currentAnimation! {
        case .video(let clip):
            setupSceneFromVideoClip(scene: scene, clip: clip)
        case .imageSequence(let clip):
            setUpSceneFromImageSequenceClip(scene: scene, clip: clip)
        }
    }

    private func reset() {
        cropNode.maskNode = nil
        cropNode.removeAllChildren()
        cropNode.removeFromParent()
        outlineNode.removeFromParent()
        imageNode = nil
        didFinishPlaying = false
    }

    func setupBackground(scene: SKScene, colors: [NSColor], background: URL?) {
        if colors.isEmpty || didSetupBackground { return }
        didSetupBackground = true

        let colorNode = SKSpriteNode(color: colors.randomElement()!, size: scene.size)
        colorNode.center(in: scene)
        colorNode.size = scene.size
        scene.addChild(colorNode)

        guard let background = background else { return }
        let backgroundNode = SKSpriteNode(texture: SKTexture(contentsOf: background))
        backgroundNode.center(in: scene)
        backgroundNode.size = scene.size
        backgroundNode.blendMode = .alpha
        scene.addChild(backgroundNode)
    }

    private func setupSnoopyHouse(scene: SKScene, houses: [URL]) {
        if houses.isEmpty || didSetupHouse { return }
        didSetupHouse = true
        let randomHouse = houses.randomElement()!
        let houseNode = SKSpriteNode(texture: SKTexture(contentsOf: randomHouse))
        houseNode.size = CGSize(width: scene.size.width * HOUSE_SCALE, height: scene.size.height * HOUSE_SCALE)
        houseNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2 - HOUSE_Y_OFFSET)
        scene.addChild(houseNode)
    }

    private func setupSceneFromVideoClip(scene: SKScene, clip: Clip<URL>) {
        let videos = expandUrls(from: clip)
        let introTransition = firstAnimation ? [] : OptionalToArray(currentTransition?.intro).map(AVPlayerItem.init(url:))
        let playItems = videos.map(AVPlayerItem.init(url:))
        let outroTransition = OptionalToArray(currentTransition?.outro).map(AVPlayerItem.init(url:))
        let totalPlayItems = introTransition + playItems + outroTransition
        let player = AVQueuePlayer(items: totalPlayItems)
        let videoNode = SKVideoNode(avPlayer: player)
        videoNode.size = scene.size
        videoNode.center(in: scene)
        cropNode.addChild(videoNode)
        outlineNode = .clear
        scene.addChild(outlineNode)
        scene.addChild(cropNode)
        videoNode.play()
        if let mask = currentMask {
            keyValueObservers.append(introTransition.last?.waitForItemReady { [weak self] _ in
                let transitionTime = introTransition.map(\.duration).reduce(CMTime.zero, CMTimeAdd)
                self?.setupMask(scene: scene, player: player, atTime: transitionTime, mask: mask.mask.intro!, outline: mask.outline.intro!)
            })
            keyValueObservers.append(playItems.last?.waitForItemReady { [weak self] item in
                let maskTime = CMTimeMakeWithSeconds(Double(mask.mask.outro?.urls.count ?? 0) * 1.5 * MASK_INTERVAL, preferredTimescale: 600)
                self?.setupMask(scene: scene, player: player, atTime: CMTimeSubtract(item.duration, maskTime), mask: mask.mask.outro!, outline: mask.outline.outro!)
            })
        } else {
            keyValueObservers.removeAll(keepingCapacity: true)
        }
        videoDidFinishPlaying = NotificationCenter
            .default
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: totalPlayItems.last)
    }

    private func setupMask(scene: SKScene, player: AVPlayer, atTime insertTime: CMTime, mask: ImageSequence, outline: ImageSequence) {
        // observer needs to be removed after triggering,
        // or it will trigger the block multiple times.
        var observer: Any?
        observer = player.addBoundaryTimeObserver(forTimes: [NSValue(time: insertTime)], queue: .global()) {
            if let observer = observer {
                player.removeTimeObserver(observer)
            }
            DispatchQueue.main.async { [weak self] in
                self?.cropNode.maskNode = AnimatedImageNode(contentsOf: mask.urls).fullscreen(in: scene)
                self?.outlineNode.reset(contentsOf: outline.urls).fullscreen(in: scene)
            }
        }
    }

    private func setUpSceneFromImageSequenceClip(scene: SKScene, clip: Clip<ImageSequence>) {
        imageNode = AnimatedImageNode(contentsOf: expandUrls(from: clip))
        imageNode?.size = scene.size
        imageNode?.center(in: scene)
        scene.addChild(imageNode!)
    }

    @MainActor
    func videoFinishedPlaying() {
        didFinishPlaying = true
    }

    @MainActor
    func updateImageSequence() {
        if let imageNode = imageNode {
            didFinishPlaying = imageNode.update()
        }
    }

    @MainActor
    func updateMask() {
        if let maskNode = cropNode.maskNode as? AnimatedImageNode {
            let maskFinished = maskNode.update()
            let outlineFinished = outlineNode.update()
            if maskFinished && outlineFinished {
                cropNode.maskNode = nil
                outlineNode = .clear
            }
        }
    }

    func moveToTheNextAnimation(scene: SKScene) {
        guard let finishedAnimation = currentAnimation else {
            fatalError("No current animation. This function can only be called after the first animation is played.")
        }
        if let nextAnimation = animations.jumpGraph[finishedAnimation]?.randomElement() {
            if animations.rph.contains(nextAnimation) {
                currentAnimation = randomDream()
            } else {
                currentAnimation = nextAnimation
            }
        } else if ParsedFileName.isDream(finishedAnimation.name) {
            currentAnimation = animations.rph.randomElement()
        } else {
            currentAnimation = randomAnimation()
        }
        Task {
            await MainActor.run {
                setup(scene: scene)
            }
        }
    }

    private func randomAnimation() -> Animation? {
        animations.jumpGraph.keys.randomElement()
    }

    private func randomDream() -> Animation? {
        animations.dreams.randomElement()
    }

    private func expandUrls(from videoClip: Clip<URL>) -> [URL] {
        var result = OptionalToArray(videoClip.intro)
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(videoClip.loop).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(videoClip.outro))
        return result
    }

    private func expandUrls(from imageSequenceClip: Clip<ImageSequence>) -> [URL] {
        var result = imageSequenceClip.intro?.urls ?? []
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(imageSequenceClip.loop?.urls).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(imageSequenceClip.outro?.urls))
        return result
    }
}
