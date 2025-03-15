//
//  SnoopyTestAppTests.swift
//  SnoopyTestAppTests
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import Foundation
import Testing

private let BASE_URL = URL(string: "/path/to/")!

struct SnoopyTestAppTests {
    private let imageSequencesOutline = [
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000000.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000001.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000002.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000003.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000004.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000005.heic"),
    ]

    private let imageSequencesMask = [
        BASE_URL.appending(path: "101_TM001_Hide_Mask_000000.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Mask_000001.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Mask_000002.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Mask_000003.heic"),
    ]
    private let imageSequencesWithFrom = [
        // this is a hypothetical dataset. Resources doesn't contain these files
        BASE_URL.appending(path: "101_BP004_From_BP002_000000.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_000001.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_000002.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_000003.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_000004.heic"),
    ]
    private let imageSequencesWithIntro = [
        BASE_URL.appending(path: "102_SS001_Intro_000000.heic"),
        BASE_URL.appending(path: "102_SS001_Intro_000001.heic"),
        BASE_URL.appending(path: "102_SS001_Intro_000002.heic"),
    ]
    private let imageSequencesWithLoop = [
        BASE_URL.appending(path: "102_SS001_Loop_000000.heic"),
        BASE_URL.appending(path: "102_SS001_Loop_000001.heic"),
        BASE_URL.appending(path: "102_SS001_Loop_000002.heic"),
        BASE_URL.appending(path: "102_SS001_Loop_000003.heic"),
        BASE_URL.appending(path: "102_SS001_Loop_000004.heic"),
    ]
    private let imageSequencesWithTo = [
        BASE_URL.appending(path: "101_BP004_To_BP002_000000.heic"),
        BASE_URL.appending(path: "101_BP004_To_BP002_000001.heic"),
        BASE_URL.appending(path: "101_BP004_To_BP002_000002.heic"),
        BASE_URL.appending(path: "101_BP004_To_BP002_000003.heic"),
        BASE_URL.appending(path: "101_BP004_To_BP002_000004.heic"),
    ]
    private let imageSequencesWithOutro = [
        BASE_URL.appending(path: "102_SS001_Outro_000000.heic"),
        BASE_URL.appending(path: "102_SS001_Outro_000001.heic"),
        BASE_URL.appending(path: "102_SS001_Outro_000002.heic"),
        BASE_URL.appending(path: "102_SS001_Outro_000003.heic"),
    ]
    private let imageSequencesWithFromAndTo = [
        // this is a hypothetical dataset. Resources doesn't contain these files
        BASE_URL.appending(path: "101_BP004_From_BP002_To_BP003_000000.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_To_BP003_000001.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_To_BP003_000002.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_To_BP003_000003.heic"),
        BASE_URL.appending(path: "101_BP004_From_BP002_To_BP003_000004.heic"),
    ]

    private let imageSequenceWithMultipleTos = [
        BASE_URL.appending(path: "101_BP001_000000.heic"),
        BASE_URL.appending(path: "101_BP001_000001.heic"),
        BASE_URL.appending(path: "101_BP001_000002.heic"),
        BASE_URL.appending(path: "101_BP001_000003.heic"),
        BASE_URL.appending(path: "101_BP001_000004.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP003_000000.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP003_000001.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP003_000002.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP003_000003.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP002_000000.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP002_000001.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP002_000002.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP002_000003.heic"),
        BASE_URL.appending(path: "101_BP001_To_BP002_000004.heic"),
    ]
    private let specialImages = [
        BASE_URL.appending(path: "101_IS12345.heic"),
        BASE_URL.appending(path: "/101_IS4321.heic"),
    ]

    private let videoWithIntroFrom = BASE_URL.appending(path: "104_AP031_Intro_From_BP004.mov")
    private let videoWithIntro = BASE_URL.appending(path: "101_004_Intro.mov")
    private let videoWithLoop = BASE_URL.appending(path: "104_AP031_Loop.mov")
    private let videoWithOutroTo = BASE_URL.appending(path: "104_AP031_Outro_To_BP001.mov")
    private let videoWithOutro = BASE_URL.appending(path: "101_004_Outro.mov")
    private let videoWithFromAndTo = BASE_URL.appending(path: "103_CM021_From_BP004_To_BP003.mov")
    private let videoFullFledge = BASE_URL.appending(path: "104_ST005.mov")

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
        #expect(animationCollection.animations["AP031"]?.element(to: "BP001") == .video(Clip(
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
        #expect(animationCollection.animations["004"]?.element() == .video(Clip(
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
        #expect(animationCollection.animations["CM021"]?.element(to: "BP003") == .video(Clip(
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
        #expect(animationCollection.animations["ST005"]?.element() == .video(Clip(
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
        #expect(animationCollection.animations["BP004"]?.element(to: "BP002") == .imageSequence(Clip(
            name: "BP004",
            from: "BP002",
            to: "BP002",
            intro: ImageSequence(
                template: "101_BP004_From_BP002_",
                lastFile: UInt8(imageSequencesWithFrom.count - 1),
                baseURL: BASE_URL
            ),
            outro: ImageSequence(
                template: "101_BP004_To_BP002_",
                lastFile: UInt8(imageSequencesWithTo.count - 1),
                baseURL: BASE_URL
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
        #expect(animationCollection.animations["SS001"]?.element() == .imageSequence(
            Clip(
                name: "SS001",
                intro: ImageSequence(
                    template: "102_SS001_Intro_",
                    lastFile: 2,
                    baseURL: BASE_URL
                ),
                loop: ImageSequence(
                    template: "102_SS001_Loop_",
                    lastFile: 4,
                    baseURL: BASE_URL
                ),
                outro: ImageSequence(
                    template: "102_SS001_Outro_",
                    lastFile: 3,
                    baseURL: BASE_URL
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
        #expect(animationCollection.animations["BP004"]?.element(to: "BP003") == .imageSequence(
            Clip(
                name: "BP004",
                from: "BP002",
                to: "BP003",
                intro: ImageSequence(
                    template: "101_BP004_From_BP002_To_BP003_",
                    lastFile: 4,
                    baseURL: BASE_URL
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

    @Test func TestGroupImageSequencesWithMultipleTos() async throws {
        let animationCollection = AnimationCollection.from(files: imageSequenceWithMultipleTos.shuffled())
        #expect(animationCollection.specialImages.count == 0)
        #expect(animationCollection.animations.count == 1)
        #expect(animationCollection.animations.keys.first == "BP001")
        #expect(animationCollection.animations["BP001"]!.count == 2)
        #expect(animationCollection.animations["BP001"]?.element(to: "BP003") == .imageSequence(
            Clip(
                name: "BP001",
                to: "BP003",
                intro: ImageSequence(template: "101_BP001_", lastFile: 4, baseURL: BASE_URL),
                outro: ImageSequence(template: "101_BP001_To_BP003_", lastFile: 3, baseURL: BASE_URL)
            )
        ))
        #expect(animationCollection.animations["BP001"]?.element(to: "BP002") == .imageSequence(
            Clip(
                name: "BP001",
                to: "BP002",
                intro: ImageSequence(template: "101_BP001_", lastFile: 4, baseURL: BASE_URL),
                outro: ImageSequence(template: "101_BP001_To_BP002_", lastFile: 4, baseURL: BASE_URL)
            )
        ))
    }
}
