//
//  ParsedFileNameTests.swift
//  SnoopyTestAppTests
//
//  Created by Yaxin Cheng on 2025-05-05.
//

import Testing

struct ParsedFileNameTests {
    @Test func testParseIntro() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_Intro")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isIntro)
    }

    @Test func testParseOutro() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_Outro")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isOutro)
    }

    @Test func testParseLoop() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_Loop")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isLoop)
    }

    @Test func testParseFrom() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_From_CA234")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isIntro)
        #expect(parsedName.from == "CA234")
    }

    @Test func testParseTo() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_To_CA234")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isOutro)
        #expect(parsedName.to == "CA234")
    }

    @Test func testParseFromTo() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_From_CA234_To_CA345")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isIntro)
        #expect(!parsedName.isOutro)
        #expect(parsedName.from == "CA234")
        #expect(parsedName.to == "CA345")
    }

    @Test func testParseReveal() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_Reveal")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isIntro)
        #expect(parsedName.isHideOrReveal)
    }

    @Test func testParseHide() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_Hide")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isOutro)
        #expect(parsedName.isHideOrReveal)
    }

    @Test func testParseMask() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_Mask")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isMask)
    }

    @Test func testParseOutline() async throws {
        let parsedName = ParsedFileName.from(fileName: "101_CA123_Outline")
        #expect(parsedName.resourceName == "CA123")
        #expect(parsedName.isOutline)
    }

    @Test func testExtractResourceName() async throws {
        let resourceName = ParsedFileName.extractResourceName(from: "101_CA123_Outline")
        #expect(resourceName == "CA123")
    }

    @Test func testExtractResourceNameNoUnderscore() async throws {
        let resourceName = ParsedFileName.extractResourceName(from: "101CA123Outline")
        #expect(resourceName == "101CA123Outline")
    }

    @Test func testExtractImageSequenceNamePrefix() async throws {
        let resourceName = ParsedFileName.extractImageSequenceNamePrefix(fileName: "101_CA123_Outline_001")
        #expect(resourceName == "101_CA123_Outline_")
    }

    var randomInt: Int {
        (0 ... 9).randomElement()!
    }

    @Test func testIsSnoopyHouse() async throws {
        let resourceName = "IS" + [randomInt, randomInt, randomInt].lazy.map(String.init).joined()
        #expect(ParsedFileName.isSnoopyHouse(resourceName))
    }

    @Test func testIsNotSnoopyHouse() async throws {
        #expect(!ParsedFileName.isSnoopyHouse("CA123"))
    }

    @Test func testIsBackground() async throws {
        #expect(ParsedFileName.isBackground("Background"))
    }

    @Test func testIsNotBackground() async throws {
        #expect(!ParsedFileName.isBackground("CA123"))
    }

    @Test func testIsDream() async throws {
        let resourceName = "AS" + [randomInt, randomInt, randomInt].lazy.map(String.init).joined()
        #expect(ParsedFileName.isDream(resourceName))
    }

    @Test func testIsNotDream() async throws {
        #expect(!ParsedFileName.isDream("CA123"))
    }

    @Test func testIsDreamTransition() async throws {
        let resourceName = "ST" + [randomInt, randomInt, randomInt].lazy.map(String.init).joined()
        #expect(ParsedFileName.isDreamTransition(resourceName))
    }

    @Test func testIsNotDreamTransition() async throws {
        #expect(!ParsedFileName.isDreamTransition("CA123"))
    }

    @Test func testIsMask() async throws {
        let resourceName = "TM" + [randomInt, randomInt, randomInt].lazy.map(String.init).joined()
        #expect(ParsedFileName.isMask(resourceName))
    }

    @Test func testIsNotMask() async throws {
        #expect(!ParsedFileName.isMask("CA123"))
    }

    @Test func testIsRph() async throws {
        #expect(ParsedFileName.isRph("RPH"))
    }

    @Test func testIsNotRph() async throws {
        #expect(!ParsedFileName.isRph("CA123"))
    }

    @Test func testIsDecoration() async throws {
        let resourceNameIv = "IV" + [randomInt, randomInt, randomInt].lazy.map(String.init).joined()
        #expect(ParsedFileName.isDecoration(resourceNameIv))
        let resourceNameWe = "WE" + [randomInt, randomInt, randomInt].lazy.map(String.init).joined()
        #expect(ParsedFileName.isDecoration(resourceNameWe))
    }

    @Test func testIsNotDecoration() async throws {
        #expect(!ParsedFileName.isDecoration("CA123"))
    }
}
