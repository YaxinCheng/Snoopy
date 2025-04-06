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
private let TIMER_INTERNVAL: TimeInterval = 0.06
private let HOUSE_SCALE: CGFloat = 720 / 1080
private let HOUSE_Y_OFFSET: CGFloat = 180 / 1080

@MainActor
final class SnoopyViewModel: ObservableObject {
    private static let resourceFiles =
        Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
    private let animations = AnimationCollection.from(files: resourceFiles)
    @Published var currentAnimation: Animation?
    @Published var didFinishPlaying: Bool = false

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

    private var videoNode: SKVideoNode? = nil {
        willSet {
            videoNode?.removeFromParent()
        }
    }

    private(set) var videoDidFinishPlaying = NotificationCenter.default.publisher(for: Notification.Name(rawValue: ""))

    private var imageNode: SKSpriteNode? = nil {
        willSet {
            imageNode?.removeFromParent()
        }
    }

    let imageSequenceTimer = Timer.publish(every: TIMER_INTERNVAL, on: .main, in: .common).autoconnect()
    private var imageSequenceIndex: Int = -1
    private var images: [URL] = []

    func setup(scene: SKScene) {
        if currentAnimation == nil {
            currentAnimation = randomAnimation()
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
        videoNode = nil
        imageNode = nil
        imageSequenceIndex = 0
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
        videoNode = SKVideoNode(avPlayer: AVQueuePlayer(items: playItems))
        videoNode?.size = scene.size
        videoNode?.center(in: scene)
        videoNode?.play()
        scene.addChild(videoNode!)
        videoDidFinishPlaying = NotificationCenter
            .default
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: playItems.last)
    }

    private func setUpSceneFromImageSequenceClip(scene: SKScene, clip: Clip<ImageSequence>) {
        images = expandUrls(from: clip)
        imageNode = SKSpriteNode(texture: SKTexture(contentsOf: images[imageSequenceIndex]))
        imageNode?.size = scene.size
        imageNode?.center(in: scene)
        scene.addChild(imageNode!)
    }

    func videoFinishedPlaying() {
        didFinishPlaying = true
    }

    func updateImageSequence() {
        guard videoNode == nil else { return }
        imageSequenceIndex += 1
        if imageSequenceIndex >= images.count && images.count > 0 {
            didFinishPlaying = true
        } else {
            imageNode?.texture = SKTexture(contentsOf: images[imageSequenceIndex])
        }
    }

    func moveToTheNextAnimation(scene: SKScene) {
        if let currentAnimation = currentAnimation,
           let nextAnimation = animations[currentAnimation]?.randomElement()
        {
            self.currentAnimation = nextAnimation
        } else {
            currentAnimation = randomAnimation()
        }
        setup(scene: scene)
    }

    private func randomAnimation() -> Animation? {
        animations.keys.randomElement()
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
