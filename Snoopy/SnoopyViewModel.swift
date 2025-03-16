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

final class SnoopyViewModel: ObservableObject {
    private static let resourceFiles =
        Bundle(for: SnoopyViewModel.self).urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
    private let animations = AnimationCollection.from(files: resourceFiles)
    @Published var currentAnimation: Animation?
    @Published var didFinishPlaying: Bool = false

    private let backgroundColors: [NSColor] = [
        .blue.withAlphaComponent(0.5),
        .systemPink,
        .yellow.withAlphaComponent(0.5),
        .cyan,
        .black,
        .systemMint
    ]
    private var didSetupBackground = false
    private var didSetupHouse = false

    private var videoNode: SKVideoNode? = nil {
        willSet {
            videoNode?.removeFromParent()
        }
    }

    private(set) var videoDidFinishPlaying: NotificationCenter.Publisher = NotificationCenter.default.publisher(for: Notification.Name(rawValue: ""))

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
        videoNode = nil
        imageNode = nil
        imageSequenceIndex = 0
        didFinishPlaying = false
        setupBackground(scene: scene, colors: backgroundColors, background: animations.background)
        setupSnoopyHouse(scene: scene, houses: animations.specialImages)
        switch currentAnimation {
        case .video(let clip):
            setupSceneFromVideoClip(scene: scene, clip: clip)
        case .imageSequence(let clip):
            setUpSceneFromImageSequenceClip(scene: scene, clip: clip)
        case nil:
            return
        }
    }

    private func setupBackground(scene: SKScene, colors: [NSColor], background: URL?) {
        if colors.isEmpty || didSetupBackground { return }
        didSetupBackground = true

        let colorNode = SKSpriteNode(color: colors.randomElement()!, size: scene.size)
        colorNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        colorNode.size = scene.size
        scene.addChild(colorNode)

        guard let background = background else { return }
        let backgroundNode = SKSpriteNode(texture: .init(imageNamed: background.path()))
        backgroundNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        backgroundNode.size = scene.size
        backgroundNode.blendMode = .alpha
        scene.addChild(backgroundNode)
    }

    private func setupSnoopyHouse(scene: SKScene, houses: [URL]) {
        if houses.isEmpty || didSetupHouse { return }
        didSetupHouse = true
        let randomHouse = houses.randomElement()!
        let houseNode = SKSpriteNode()
        houseNode.texture = SKTexture(imageNamed: randomHouse.path())
        houseNode.size = CGSize(width: scene.size.width * HOUSE_SCALE, height: scene.size.height * HOUSE_SCALE)
        houseNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2 - HOUSE_Y_OFFSET)
        scene.addChild(houseNode)
    }

    private func setupSceneFromVideoClip(scene: SKScene, clip: Clip<URL>) {
        let videos = expandUrls(from: clip)
        let playItems = videos.map(AVPlayerItem.init(url:))
        videoNode = SKVideoNode(avPlayer: AVQueuePlayer(items: playItems))
        videoNode?.size = scene.size
        videoNode?.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        videoNode?.play()
        scene.addChild(videoNode!)
        videoDidFinishPlaying = NotificationCenter
            .default
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: playItems.last)
    }

    private func setUpSceneFromImageSequenceClip(scene: SKScene, clip: Clip<ImageSequence>) {
        images = expandUrls(from: clip)
        imageNode = SKSpriteNode()
        imageNode?.size = scene.size
        imageNode?.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        imageNode?.texture = SKTexture(imageNamed: images[imageSequenceIndex].path())
        scene.addChild(imageNode!)
    }

    func videoFinishedPlaying() {
        didFinishPlaying = true
    }

    func updateImageSequence() {
        imageSequenceIndex += 1
        if imageSequenceIndex >= images.count && images.count > 0 {
            didFinishPlaying = true
        } else {
            imageNode?.texture = SKTexture(imageNamed: images[imageSequenceIndex].path())
        }
    }

    func moveToTheNextAnimation(scene: SKScene) {
        if let nextAnimationName = currentAnimation?.to {
            guard let nextAnimation = animations[nextAnimationName]?.randomAnimation() else {
                fatalError("Cannot find the next animation \"\(nextAnimationName)\"")
            }
            currentAnimation = nextAnimation
        } else {
            currentAnimation = randomAnimation()
        }
        setup(scene: scene)
    }

    private func randomAnimation() -> Animation? {
        animations.values.randomElement()?.randomAnimation()
    }

    func expandUrls(from videoClip: Clip<URL>) -> [URL] {
        var result = [videoClip.intro!]
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(videoClip.loop).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(videoClip.outro))
        return result
    }

    func expandUrls(from imageSequenceClip: Clip<ImageSequence>) -> [URL] {
        var result = imageSequenceClip.intro?.urls ?? []
        let loopRepeatingLimit = UInt.random(in: 1...LOOP_REPEAT_LIMIT)
        result.append(contentsOf: OptionalToArray(imageSequenceClip.loop?.urls).repeat(count: loopRepeatingLimit))
        result.append(contentsOf: OptionalToArray(imageSequenceClip.outro?.urls))
        return result
    }
}
