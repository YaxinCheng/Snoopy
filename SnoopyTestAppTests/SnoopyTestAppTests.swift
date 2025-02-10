//
//  SnoopyTestAppTests.swift
//  SnoopyTestAppTests
//
//  Created by Yaxin Cheng on 2025-02-09.
//

import Foundation
@testable import SnoopyTestApp
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
        // this is a artificial dataset. Resources doesn't contain these files
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
        // this is a artificial dataset. Resources doesn't contain these files
        URL(string: "101_BP004_From_BP002_To_BP003_000000.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000001.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000002.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000003.heic")!,
        URL(string: "101_BP004_From_BP002_To_BP003_000004.heic")!,
    ]
    private let specialImages = ["IS12345.heic", "IS4321.heic"]

    private let videoWithIntroFrom = URL(string: "104_AP031_Intro_From_BP004.mov")!
    private let videoWithIntro = URL(string: "101_004_Intro.mov")!
    private let videoWithLoop = URL(string: "104_AP031_Loop.mov")!
    private let videoWithOutroTo = URL(string: "104_AP031_Outro_To_BP001.mov")!
    private let videoWithOutro = URL(string: "101_004_Outro.mov")!
    private let videoWithFromAndTo = URL(string: "103_CM021_From_BP004_To_BP003.mov")!
    private let videoFullFledge = URL(string: "104_ST005_Reveal.mov")!

    @Test func TestIgnoreOutline() async throws {
        let clipGroup = ClipGroup.groupFiles(imageSequencesOutline)
        #expect(clipGroup.clips.isEmpty)
        #expect(clipGroup.specialImages.isEmpty)
    }

    @Test func TestIgnoreMask() async throws {
        let clipGroup = ClipGroup.groupFiles(imageSequencesMask)
        #expect(clipGroup.clips.isEmpty)
        #expect(clipGroup.specialImages.isEmpty)
    }

    @Test func TestVideoGroupIntroFromLoopOutroTo() async throws {
        let clipGroup = ClipGroup.groupFiles(
            [videoWithIntroFrom, videoWithLoop, videoWithOutroTo].shuffled())
        #expect(clipGroup.specialImages.isEmpty)
        #expect(clipGroup.clips.count == 1)
        #expect(clipGroup.clips.keys.first == "AP031")
        #expect(clipGroup.clips["AP031"] == .video(Animation(
            name: "AP031",
            from: "BP004",
            to: "BP001",
            intro: videoWithIntroFrom,
            loop: videoWithLoop,
            outro: videoWithOutroTo
        )))
    }

    @Test func TestVideoGroupIntroAndOutro() async throws {
        let clipGroup = ClipGroup.groupFiles([
            videoWithIntro, videoWithOutro,
        ].shuffled())
        #expect(clipGroup.specialImages.isEmpty)
        #expect(clipGroup.clips.count == 1)
        #expect(clipGroup.clips.keys.first == "004")
        #expect(clipGroup.clips["004"] == .video(Animation(
            name: "004",
            intro: videoWithIntro,
            outro: videoWithOutro
        )))
    }

    @Test func TestVideoGroupFromAndTo() async throws {
        let clipGroup = ClipGroup.groupFiles([
            videoWithFromAndTo,
        ])
        #expect(clipGroup.specialImages.isEmpty)
        #expect(clipGroup.clips.count == 1)
        #expect(clipGroup.clips.keys.first == "CM021")
        #expect(clipGroup.clips["CM021"] == .video(Animation(
            name: "CM021",
            from: "BP004",
            to: "BP003",
            intro: videoWithFromAndTo
        )))
    }

    @Test func TestVideoGroupFullFledged() async throws {
        let clipGroup = ClipGroup.groupFiles([
            videoFullFledge,
        ])
        #expect(clipGroup.specialImages.isEmpty)
        #expect(clipGroup.clips.count == 1)
        #expect(clipGroup.clips.keys.first == "ST005")
        #expect(clipGroup.clips["ST005"] == .video(Animation(
            name: "ST005",
            intro: videoFullFledge
        )))
    }

    @Test func TestImageGroupFromTo() async throws {
        let clipGroup = ClipGroup.groupFiles(
            (imageSequencesWithFrom + imageSequencesWithTo)
                .shuffled())
        #expect(clipGroup.specialImages.isEmpty)
        #expect(clipGroup.clips.count == 1)
        #expect(clipGroup.clips.keys.first == "BP004")
        #expect(clipGroup.clips["BP004"] == .imageSequence(Animation(
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
}
