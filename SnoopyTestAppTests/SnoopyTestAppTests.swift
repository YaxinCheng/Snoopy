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
    private let imageSequencesOutlineReveal = [
        BASE_URL.appending(path: "101_TM001_Reveal_Outline_000000.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Outline_000001.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Outline_000002.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Outline_000003.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Outline_000004.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Outline_000005.heic"),
    ]

    private let imageSequencesOutlineHide = [
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000000.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000001.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000002.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000003.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000004.heic"),
        BASE_URL.appending(path: "101_TM001_Hide_Outline_000005.heic"),
    ]

    private let imageSequencesMaskReveal = [
        BASE_URL.appending(path: "101_TM001_Reveal_Mask_000000.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Mask_000001.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Mask_000002.heic"),
        BASE_URL.appending(path: "101_TM001_Reveal_Mask_000003.heic"),
    ]

    private let imageSequencesMaskHide = [
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
        BASE_URL.appending(path: "101_IS4321.heic"),
    ]

    private let videoWithIntroFrom = BASE_URL.appending(path: "104_AP031_Intro_From_BP004.mov")
    private let videoWithIntro = BASE_URL.appending(path: "101_CA004_Intro.mov")
    private let videoWithLoop = BASE_URL.appending(path: "104_AP031_Loop.mov")
    private let videoWithOutroTo = BASE_URL.appending(path: "104_AP031_Outro_To_BP001.mov")
    private let videoWithOutro = BASE_URL.appending(path: "101_CA004_Outro.mov")
    private let videoWithFromAndTo = BASE_URL.appending(path: "103_CM021_From_BP004_To_BP003.mov")
    private let videoFullFledge = BASE_URL.appending(path: "104_CM005.mov")
    private let videoWithDreamContent = BASE_URL.appending(path: "101_AS005.mov")
    private let videoTransitionHideA = BASE_URL.appending(path: "101_ST001_Hide_A.mov")
    private let videoTransitionHideB = BASE_URL.appending(path: "101_ST001_Hide_B.mov")
    private let videoTransitionRevealA = BASE_URL.appending(path: "101_ST001_Reveal_A.mov")
    private let videoTransitionRevealB = BASE_URL.appending(path: "101_ST001_Reveal_B.mov")

    @Test func TestMaskOutline() async throws {
        // 101_TM001_Hide_Outline_
        let animationCollection = AnimationCollection.from(files:
            (imageSequencesOutlineReveal + imageSequencesOutlineHide + imageSequencesMaskHide + imageSequencesMaskReveal).shuffled())
        #expect(animationCollection.jumpGraph.isEmpty)
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.masks.count == 1)
        #expect(animationCollection.masks.first?.value.mask == Clip(
            name: "TM001",
            kind: .mask,
            intro: ImageSequence(
                prefix: "101_TM001_Reveal_Mask_",
                lastFile: 3,
                baseURL: BASE_URL
            ),
            outro: ImageSequence(
                prefix: "101_TM001_Hide_Mask_",
                lastFile: 3,
                baseURL: BASE_URL
            ),
        ))
        #expect(animationCollection.masks.first?.value.outline == Clip(
            name: "TM001",
            kind: .outline,
            intro: ImageSequence(
                prefix: "101_TM001_Reveal_Outline_",
                lastFile: 5,
                baseURL: BASE_URL
            ),
            outro: ImageSequence(
                prefix: "101_TM001_Hide_Outline_",
                lastFile: 5,
                baseURL: BASE_URL
            )
        ))
    }

    @Test func TestTransitionWithVariations() async throws {
        let animationCollection = AnimationCollection.from(files: [
            videoTransitionHideA, videoTransitionHideB, videoTransitionRevealA, videoTransitionRevealB,
        ].shuffled())
        #expect(animationCollection.jumpGraph.isEmpty)
        #expect(animationCollection.dreamTransitions.count == 4)
        #expect(animationCollection.dreamTransitions.sorted { $0.outro!.path() < $1.outro!.path() || $0.intro!.path() < $1.intro!.path() } == [
            Clip(name: "ST001", intro: videoTransitionRevealA, outro: videoTransitionHideA),
            Clip(name: "ST001", intro: videoTransitionRevealA, outro: videoTransitionHideB),
            Clip(name: "ST001", intro: videoTransitionRevealB, outro: videoTransitionHideA),
            Clip(name: "ST001", intro: videoTransitionRevealB, outro: videoTransitionHideB),
        ])
    }

    @Test func TestVideoGroupIntroFromLoopOutroTo() async throws {
        // 104_AP031_Intro_From_BP004 + 104_AP031_Loop + 104_AP031_Outro_To_BP001
        let animationCollection = AnimationCollection.from(
            files: [videoWithIntroFrom, videoWithLoop, videoWithOutroTo].shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.jumpGraph.count == 1)
        #expect(animationCollection.jumpGraph.keys.first == .video(Clip(
            name: "AP031",
            intro: videoWithIntroFrom,
            loop: videoWithLoop,
            outro: videoWithOutroTo
        )))
    }

    @Test func TestVideoGroupWithoutIntro() async throws {
        // 101_CA004_Outro
        let animationCollection = AnimationCollection.from(files: [
            videoWithOutro,
        ].shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.jumpGraph.count == 0)
    }

    @Test func TestVideoGroupIntroAndOutro() async throws {
        // 101_CA004_Intro + 101_CA004_Outro
        let animationCollection = AnimationCollection.from(files: [
            videoWithIntro, videoWithOutro,
        ].shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.jumpGraph.count == 1)
        #expect(animationCollection.jumpGraph.keys.first == .video(Clip(
            name: "CA004",
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
        #expect(animationCollection.jumpGraph.count == 1)
        #expect(animationCollection.jumpGraph.keys.first == .video(Clip(
            name: "CM021",
            intro: videoWithFromAndTo
        )))
    }

    @Test func TestVideoGroupFullFledged() async throws {
        // 104_ST005_Reveal
        let animationCollection = AnimationCollection.from(files: [
            videoFullFledge,
        ])
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.jumpGraph.count == 1)
        #expect(animationCollection.jumpGraph.keys.first == .video(Clip(
            name: "CM005",
            intro: videoFullFledge
        )))
    }

    @Test func TestImageGroupFromTo() async throws {
        // 101_BP004_From_BP002_ + 101_BP004_To_BP002_
        let animationCollection = AnimationCollection.from(
            files: (imageSequencesWithFrom + imageSequencesWithTo)
                .shuffled())
        #expect(animationCollection.specialImages.isEmpty)
        #expect(animationCollection.jumpGraph.count == 1)
        #expect(animationCollection.jumpGraph.keys.first == .imageSequence(Clip(
            name: "BP004",
            intro: ImageSequence(
                prefix: "101_BP004_From_BP002_",
                lastFile: UInt8(imageSequencesWithFrom.count - 1),
                baseURL: BASE_URL
            ),
            outro: ImageSequence(
                prefix: "101_BP004_To_BP002_",
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
        #expect(animationCollection.jumpGraph.count == 1)
        #expect(animationCollection.jumpGraph.keys.first == .imageSequence(
            Clip(
                name: "SS001",
                intro: ImageSequence(
                    prefix: "102_SS001_Intro_",
                    lastFile: 2,
                    baseURL: BASE_URL
                ),
                loop: ImageSequence(
                    prefix: "102_SS001_Loop_",
                    lastFile: 4,
                    baseURL: BASE_URL
                ),
                outro: ImageSequence(
                    prefix: "102_SS001_Outro_",
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
        #expect(animationCollection.jumpGraph.count == 1)
        #expect(animationCollection.jumpGraph.keys.first == .imageSequence(
            Clip(
                name: "BP004",
                intro: ImageSequence(
                    prefix: "101_BP004_From_BP002_To_BP003_",
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
        let animations = animationCollection.jumpGraph.sorted {
            $0.key.name < $1.key.name || ($0.key.urls.last?.path() ?? "") < ($1.key.urls.last?.path() ?? "")
        }
        #expect(animations.count == 3)
        #expect(animations[0].key == .imageSequence(
            Clip(
                name: "BP001",
                intro: ImageSequence(prefix: "101_BP001_", lastFile: 4, baseURL: BASE_URL),
            )
        ))
        #expect(animations[1].key == .imageSequence(
            Clip(
                name: "BP001",
                intro: ImageSequence(prefix: "101_BP001_", lastFile: 4, baseURL: BASE_URL),
                outro: ImageSequence(prefix: "101_BP001_To_BP002_", lastFile: 4, baseURL: BASE_URL)
            )
        ))
        #expect(animations[2].key == .imageSequence(
            Clip(
                name: "BP001",
                intro: ImageSequence(prefix: "101_BP001_", lastFile: 4, baseURL: BASE_URL),
                outro: ImageSequence(prefix: "101_BP001_To_BP003_", lastFile: 3, baseURL: BASE_URL)
            )
        ))
    }

    @Test func TestDreamContent() async throws {
        let animationCollection = AnimationCollection.from(files: [videoWithDreamContent])
        #expect(animationCollection.dreams == [
            .video(Clip(
                name: "AS005",
                intro: videoWithDreamContent
            )),
        ])
    }
}
