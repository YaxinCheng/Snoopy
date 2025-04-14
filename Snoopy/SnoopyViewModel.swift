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

final class SnoopyViewModel: ObservableObject {
    private static let resourceFiles =
        Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
    private let animations = AnimationCollection.from(files: resourceFiles)
    @Published var currentAnimation: Animation? {
        willSet {
            print("\(currentAnimation?.name ?? "nil"), \(newValue?.name ?? "nil")")
            let needsMask = currentAnimation == nil || (newValue.map(\.name).map(ParsedFileName.isDream) ?? false)
            if needsMask {
                currentMask = animations.masks.randomElement()
            } else {
                currentMask = nil
            }
            firstAnimation = currentAnimation == nil
        }
    }

    @Published var didFinishPlaying: Bool = false
    private var firstAnimation = true
    private var currentMask: Mask?

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

    private var outlineNode: AnimatedImageNode? = nil {
        willSet {
            outlineNode?.removeFromParent()
        }
    }

    private(set) var videoDidFinishPlaying = NotificationCenter.default.publisher(for: Notification.Name(rawValue: ""))
    private var observeAVPlayerStatus: Any?

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
        outlineNode = nil
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
        let playItems = videos.map(AVPlayerItem.init(url:))
        let player = AVQueuePlayer(items: playItems)
        // TODO: this is for testing only. Remove it
        player.seek(to: CMTimeMakeWithSeconds(28, preferredTimescale: 600))
        let videoNode = SKVideoNode(avPlayer: player)
        videoNode.size = scene.size
        videoNode.center(in: scene)
        cropNode = SKCropNode()
        if let resources = currentMask?.mask.intro, !firstAnimation {
            cropNode.maskNode = AnimatedImageNode(contentsOf: resources.urls).fullscreen(in: scene)
        }
        if let resources = currentMask?.outline.intro, !firstAnimation {
            outlineNode = AnimatedImageNode(contentsOf: resources.urls).fullscreen(in: scene)
        }
        cropNode.addChild(videoNode)
        if let outlineNode = outlineNode {
            scene.addChild(outlineNode)
        }
        scene.addChild(cropNode)
        videoNode.play()
        if currentMask != nil {
            observeAVPlayerStatus = playItems.last?.observe(\.status, options: [.new, .initial]) { [weak self] observedItem, _ in
                guard observedItem.status == .readyToPlay, let mask = self?.currentMask else { return }
                let outroTime = (Double(mask.mask.outro?.urls.count ?? 0) + 2) * MASK_INTERVAL
                let outroMaskTimeDuration = CMTimeSubtract(observedItem.duration, CMTimeMakeWithSeconds(outroTime, preferredTimescale: 600))
                player.addBoundaryTimeObserver(forTimes: [NSValue(time: outroMaskTimeDuration)], queue: .global()) { [weak self] in
                    DispatchQueue.main.async {
                        if let resources = mask.mask.outro?.urls {
                            self?.cropNode.maskNode = AnimatedImageNode(contentsOf: resources).fullscreen(in: scene)
                        }
                        if let resources = mask.outline.outro?.urls {
                            self?.outlineNode = AnimatedImageNode(contentsOf: resources).fullscreen(in: scene)
                        }
                    }
                }
            }
        } else {
            observeAVPlayerStatus = nil
        }
        videoDidFinishPlaying = NotificationCenter
            .default
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: playItems.last)
    }

    private func setUpSceneFromImageSequenceClip(scene: SKScene, clip: Clip<ImageSequence>) {
        imageNode = AnimatedImageNode(contentsOf: expandUrls(from: clip))
        imageNode?.size = scene.size
        imageNode?.center(in: scene)
        scene.addChild(imageNode!)
    }

    @MainActor
    func videoFinishedPlaying() {
        didFinishPlaying = (cropNode.maskNode as? AnimatedImageNode)?.isFinished ?? true
    }

    @MainActor
    func updateImageSequence() {
        if let imageNode = imageNode {
            didFinishPlaying = imageNode.update()
        }
    }

    @MainActor
    func updateMask() {
        if let maskNode = cropNode.maskNode as? AnimatedImageNode, let outlineNode = outlineNode {
            didFinishPlaying = maskNode.update() && outlineNode.update()
        }
    }

    func moveToTheNextAnimation(scene: SKScene) {
        if let currentAnimation = currentAnimation,
           let nextAnimation = animations.jumpGraph[currentAnimation]?.randomElement()
        {
            self.currentAnimation = nextAnimation
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
