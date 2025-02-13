//
//  SnoopyTestAppTests.swift
//  SnoopyTestAppTests
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import Foundation
import Testing

struct SnoopyTestAppTests {
    private let imageSequencesOutline = [
        URL(string: "101_TM001_Hide_Outline_000000.heic")!,
        URL(string: "101_TM001_Hide_Outline_000001.heic")!,
        URL(string: "101_TM001_Hide_Outline_000002.heic")!,
        URL(string: "101_TM001_Hide_Outline_000003.heic")!,
        URL(string: "101_TM001_Hide_Outline_000004.heic")!,
        URL(string: "101_TM001_Hide_Outline_000005.heic")!,
    ]

    private let imageSequencesMask = [
        URL(string: "101_TM001_Hide_Mask_000000.heic")!,
        URL(string: "101_TM001_Hide_Mask_000001.heic")!,
        URL(string: "101_TM001_Hide_Mask_000002.heic")!,
        URL(string: "101_TM001_Hide_Mask_000003.heic")!,
    ]
    private let imageSequencesWithFrom = [
        // this is a hypothetical dataset. Resources doesn't contain these files
        URL(string: "101_BP004_From_BP002_000000.heic")!,
        URL(string: "101_BP004_From_BP002_000001.heic")!,
        URL(string: "101_BP004_From_BP002_000002.heic")!,
        URL(string: "101_BP004_From_BP002_000003.heic")!,
        URL(string: "101_BP004_From_BP002_000004.heic")!,
    ]
    private let imageSequencesWithIntro = [
        URL(string: "102_SS001_Intro_000000.heic")!,
        URL(string: "102_SS001_Intro_000001.heic")!,
        URL(string: "102_SS001_Intro_000002.heic")!,
    ]
    private let imageSequencesWithLoop = [
        URL(string: "102_SS001_Loop_000000.heic")!,
        URL(string: "102_SS001_Loop_000001.heic")!,
        URL(string: "102_SS001_Loop_000002.heic")!,
        URL(string: "102_SS001_Loop_000003.heic")!,
        URL(string: "102_SS001_Loop_000004.heic")!,
    ]
    private let imageSequencesWithTo = [
        URL(string: "101_BP004_To_BP002_000000.heic")!,
        URL(string: "101_BP004_To_BP002_000001.heic")!,
        URL(string: "101_BP004_To_BP002_000002.heic")!,
        URL(string: "101_BP004_To_BP002_000003.heic")!,
        URL(string: "101_BP004_To_BP002_000004.heic")!,
    ]
    private let imageSequencesWithOutro = [
        URL(string: "102_SS001_Outro_000000.heic")!,
        URL(string: "102_SS001_Outro_000001.heic")!,
        URL(string: "102_SS001_Outro_000002.heic")!,
        URL(string: "102_SS001_Outro_000003.heic")!,
    ]
    private let imageSequencesWithFromAndTo = [
        // this is a hypothetical dataset. Resources doesn't contain these files
        URL(string: "101_BP004_From_BP002_To_BP003_000000.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000001.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000002.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000003.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000004.heic")!,
    ]
    private let specialImages = [URL(string: "101_IS12345.heic")!, URL(string: "101_IS4321.heic")!]

    private let videoWithIntroFrom = URL(string: "104_AP031_Intro_From_BP004.mov")!
    private let videoWithIntro = URL(string: "101_004_Intro.mov")!
    private let videoWithLoop = URL(string: "104_AP031_Loop.mov")!
    private let videoWithOutroTo = URL(string: "104_AP031_Outro_To_BP001.mov")!
    private let videoWithOutro = URL(string: "101_004_Outro.mov")!
    private let videoWithFromAndTo = URL(string: "103_CM021_From_BP004_To_BP003.mov")!
    private let videoFullFledge = URL(string: "104_ST005_Reveal.mov")!

    @Test func TestIgnoreOutline() async throws {
        // 101_TM001_Hide_Outline_
        let animationCollection = AnimationCollection.from(files: imageSequencesOutline)
        #expect(animationCollection.animations.isEmpty)
        #expect(animationCollection.specialImages.isEmpty)
    }

    @Test func TestIgnoreMask() async throws {
        // 101_TM001_Hide_Mask_
        let animationCollection = AnimationCollection.from(files: imageSequencesMask)
        #expect(animationCollection.animations.isEmpty)
        #expect(animationCollection.specialImages.isEmpty)
    }

    @Test func TestVideoGroupIntroFromLoopOutroTo() async throws {
        // 104_AP031_Intro_From_BP004 + 104_AP031_Loop + 104_AP031_Outro_To_BP001
        let animationCollection = AnimationCollection.from(
            files: [videoWithIntroFrom, videoWithLoop, videoWithOutroTo].shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "AP031")
        #expect(animationCollection.animations["AP031"] == .video(Clip(
            name: "AP031",
            from: "BP004",
            to: "BP001",
            intro: videoWithIntroFrom,
            loop: videoWithLoop,
            outro: videoWithOutroTo
        )))
    }

    @Test func TestVideoGroupIntroAndOutro() async throws {
        // 101_004_Intro + 101_004_Outro
        let animationCollection = AnimationCollection.from(files: [
            videoWithIntro, videoWithOutro,
        ].shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "004")
        #expect(animationCollection.animations["004"] == .video(Clip(
            name: "004",
            intro: videoWithIntro,
            outro: videoWithOutro
        )))
    }

    @Test func TestVideoGroupFromAndTo() async throws {
        // 103_CM021_From_BP004_To_BP003
        let animationCollection = AnimationCollection.from(files: [
            videoWithFromAndTo,
        ])
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "CM021")
        #expect(animationCollection.animations["CM021"] == .video(Clip(
            name: "CM021",
            from: "BP004",
            to: "BP003",
            intro: videoWithFromAndTo
        )))
    }

    @Test func TestVideoGroupFullFledged() async throws {
        // 104_ST005_Reveal
        let animationCollection = AnimationCollection.from(files: [
            videoFullFledge,
        ])
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "ST005")
        #expect(animationCollection.animations["ST005"] == .video(Clip(
            name: "ST005",
            intro: videoFullFledge
        )))
    }

    @Test func TestImageGroupFromTo() async throws {
        // 101_BP004_From_BP002_ + 101_BP004_To_BP002_
        let animationCollection = AnimationCollection.from(
            files: (imageSequencesWithFrom + imageSequencesWithTo)
                .shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "BP004")
        #expect(animationCollection.animations["BP004"] == .imageSequence(Clip(
            name: "BP004",
            from: "BP002",
            to: "BP002",
            intro: ImageSequence(
                template: "101_BP004_From_BP002_%06d",
                lastFile: UInt8(imageSequencesWithFrom.count - 1)
            ),
            outro: ImageSequence(
                template: "101_BP004_To_BP002_%06d",
                lastFile: UInt8(imageSequencesWithTo.count - 1)
            )
        )))
    }

    @Test func TestImageGroupIntroLoopOutro() async throws {
        // 102_SS001_Intro_ + 102_SS001_Loop_ + 102_SS001_Outro_
        let animationCollection = AnimationCollection.from(
            files: (imageSequencesWithIntro + imageSequencesWithLoop + imageSequencesWithOutro)
                .shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "SS001")
        #expect(animationCollection.animations["SS001"] == .imageSequence(
            Clip(
                name: "SS001",
                intro: ImageSequence(
                    template: "102_SS001_Intro_%06d",
                    lastFile: 2
                ),
                loop: ImageSequence(
                    template: "102_SS001_Loop_%06d",
                    lastFile: 4
                ),
                outro: ImageSequence(
                    template: "102_SS001_Outro_%06d",
                    lastFile: 3
                )
            )))
    }

    @Test func TestImageGroupFromAndTo() async throws {
        // 101_BP004_From_BP002_To_BP003_
        let animationCollection = AnimationCollection.from(
            files: imageSequencesWithFromAndTo)
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "BP004")
        #expect(animationCollection.animations["BP004"] == .imageSequence(
            Clip(
                name: "BP004",
                from: "BP002",
                to: "BP003",
                intro: ImageSequence(
                    template: "101_BP004_From_BP002_To_BP003_%06d",
                    lastFile: 4
                )
            )
        ))
    }

    @Test func TestGroupFoundSpecialImages() async throws {
        let animationCollection = AnimationCollection.from(files: specialImages.shuffled())
        #expect(animationCollection.specialImages.count == 2)
        #expect(animationCollection.specialImages.sorted {
            $0.absoluteString < $1.absoluteString
        } == specialImages.sorted {
            $0.absoluteString < $1.absoluteString
        })
    }
}
