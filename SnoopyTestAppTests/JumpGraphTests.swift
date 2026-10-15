//
//  JumpGraphTests.swift
//  SnoopyTestAppTests
//
//  Created by Yaxin Cheng on 2026-10-14.
//

import Foundation
import Testing

private let BASE_URL = URL(string: "/path/to/")!

struct JumpGraphTests {
    // BP Fixtures
    private let bp001Intro = BASE_URL.appending(path: "101_BP001_000000.heic")
    private let bp001Intro1 = BASE_URL.appending(path: "101_BP001_000001.heic")
    private let bp001ToBP002_0 = BASE_URL.appending(path: "101_BP001_To_BP002_000000.heic")
    private let bp001ToBP002_1 = BASE_URL.appending(path: "101_BP001_To_BP002_000001.heic")

    private let bp002Intro = BASE_URL.appending(path: "101_BP002_000000.heic")
    private let bp002Intro1 = BASE_URL.appending(path: "101_BP002_000001.heic")
    private let bp002ToBP001_0 = BASE_URL.appending(path: "101_BP002_To_BP001_000000.heic")
    private let bp002ToBP001_1 = BASE_URL.appending(path: "101_BP002_To_BP001_000001.heic")
    private let bp002ToRPH_0 = BASE_URL.appending(path: "101_BP002_To_RPH_000000.heic")
    private let bp002ToRPH_1 = BASE_URL.appending(path: "101_BP002_To_RPH_000001.heic")

    private let bp004Intro = BASE_URL.appending(path: "101_BP004_000000.heic")
    private let bp004Intro1 = BASE_URL.appending(path: "101_BP004_000001.heic")

    // RPD Fixtures
    private let rpd001Mov = BASE_URL.appending(path: "101_RPD001.mov")
    private let rpd005Mov = BASE_URL.appending(path: "104_RPD005.mov")
    private let rpdLoopMov = BASE_URL.appending(path: "101_RPD_Loop.mov")
    private let rpdToBP001Mov = BASE_URL.appending(path: "101_RPD_To_BP001.mov")

    // RPH Fixtures
    private let rphLoopMov = BASE_URL.appending(path: "101_RPH_Loop.mov")
    private let rph002Mov = BASE_URL.appending(path: "103_RPH002.mov")
    private let rph003Mov = BASE_URL.appending(path: "104_RPH003.mov")
    private let rphToBP001_0 = BASE_URL.appending(path: "101_RPH_To_BP001_000000.heic")
    private let rphToBP001_1 = BASE_URL.appending(path: "101_RPH_To_BP001_000001.heic")
    private let rphToBP002_0 = BASE_URL.appending(path: "101_RPH_To_BP002_000000.heic")
    private let rphToBP002_1 = BASE_URL.appending(path: "101_RPH_To_BP002_000001.heic")

    // Activity Pose AP002 Fixtures
    private let ap002Intro = BASE_URL.appending(path: "101_AP002_Intro_From_BP002.mov")
    private let ap002Loop = BASE_URL.appending(path: "101_AP002_Loop.mov")
    private let ap002ToRPD = BASE_URL.appending(path: "101_AP002_To_RPD.mov")
    private let ap002ToBP004 = BASE_URL.appending(path: "101_AP002_Outro_To_BP004.mov")

    // RW (Woodstock) Fixtures
    private let rwd001Mov = BASE_URL.appending(path: "101_RWD001.mov")
    private let rwdToBP001Mov = BASE_URL.appending(path: "101_RWD_To_BP001.mov")
    private let rwh002Mov = BASE_URL.appending(path: "103_RWH002.mov")
    private let rwhToBP001Mov = BASE_URL.appending(path: "101_RWH_To_BP001.mov")

    /// Tests that the JumpGraph prioritizes idle resting poses (`!designated`) over outgoing transitions
    /// when resolving a destination state, preventing transitions from chaining immediately into outgoing transitions.
    @Test func testIdlePosePreference() {
        let files = [
            bp001Intro, bp001Intro1,
            bp001ToBP002_0, bp001ToBP002_1,
            bp002Intro, bp002Intro1,
            bp002ToBP001_0, bp002ToBP001_1,
            bp002ToRPH_0, bp002ToRPH_1,
        ]
        let collection = AnimationCollection.from(files: files)

        // Find BP001_To_BP002 transition
        let bp001ToBP002 = collection.jumpGraph.keys.first { $0.name == "BP001" && $0.designated }
        #expect(bp001ToBP002 != nil)

        let targets = collection.jumpGraph[bp001ToBP002!] ?? []
        #expect(!targets.isEmpty)
        // Must land only on idle/resting poses (!designated), never immediately on outgoing transitions
        #expect(targets.allSatisfy { !$0.designated })
        #expect(targets.allSatisfy { $0.name == "BP002" })
    }

    /// Tests that transition-only groups (like RPD where all clips merge into outro_To_BP)
    /// fall back to available animations so they don't produce empty destination lists.
    @Test func testFallbackForTransitionOnlyGroups() {
        let files = [
            rpd001Mov, rpd005Mov, rpdLoopMov, rpdToBP001Mov,
            ap002Intro, ap002Loop, ap002ToRPD,
        ]
        let collection = AnimationCollection.from(files: files)

        let ap002ToRPDAnim = collection.jumpGraph.keys.first { $0.name == "AP002" && $0.designated }
        #expect(ap002ToRPDAnim != nil)

        let targets = collection.jumpGraph[ap002ToRPDAnim!] ?? []
        #expect(!targets.isEmpty)
        #expect(targets.contains { $0.name == "RPD001" })
        #expect(targets.contains { $0.name == "RPD005" })
    }

    /// Tests that generic destination prefixes without a numeric suffix (e.g. "RPD")
    /// correctly resolve to all variations matching that prefix ("RPD001", "RPD005").
    @Test func testGenericDestinationPrefixMatching() {
        let files = [
            ap002Intro, ap002Loop, ap002ToRPD,
            rpd001Mov, rpd005Mov, rpdLoopMov, rpdToBP001Mov,
        ]
        let collection = AnimationCollection.from(files: files)

        let ap002Anim = collection.jumpGraph.keys.first { $0.name == "AP002" }!
        let nextAnimations = collection.jumpGraph[ap002Anim] ?? []

        let names = Set(nextAnimations.map(\.name))
        #expect(names.contains("RPD001"))
        #expect(names.contains("RPD005"))
    }

    /// Tests that AP002 outro transitions correctly route to their designated destinations:
    /// _To_RPD routes to RPD variations, and _To_BP004 routes to idle BP004.
    @Test func testActivityPoseOutroResolution() {
        let files = [
            ap002Intro, ap002Loop, ap002ToRPD, ap002ToBP004,
            rpd001Mov, rpdLoopMov, rpdToBP001Mov,
            bp004Intro, bp004Intro1,
        ]
        let collection = AnimationCollection.from(files: files)

        let ap002Anims = collection.jumpGraph.keys.filter { $0.name == "AP002" }
        #expect(ap002Anims.count == 2)

        for anim in ap002Anims {
            let targets = collection.jumpGraph[anim] ?? []
            #expect(!targets.isEmpty)
            let targetNames = Set(targets.map(\.name))
            #expect(targetNames.contains("RPD001") || targetNames.contains("BP004"))
        }
    }

    /// Tests that solitary sleeping and roof poses never route into Woodstock clips,
    /// and that post-dream wake animations are strictly solitary RPH exit sequences.
    @Test func testSolitaryStateWoodstockIsolation() {
        let files = [
            rphLoopMov, rph002Mov, rphToBP001_0, rphToBP001_1,
            rwd001Mov, rwdToBP001Mov,
            rwh002Mov, rwhToBP001Mov,
            rpd001Mov, rpdLoopMov, rpdToBP001Mov,
            bp001Intro, bp001Intro1,
        ]
        let collection = AnimationCollection.from(files: files)

        // Post-dream wake animations must strictly be solitary RPH exit transitions
        #expect(!collection.wakeAnimations.isEmpty)
        #expect(collection.wakeAnimations.allSatisfy { $0.name == "RPH" && $0.designated })
        #expect(collection.wakeAnimations.allSatisfy { !$0.name.starts(with: "RW") })
        #expect(collection.wakeAnimations.allSatisfy { !$0.name.starts(with: "RPD") })

        // Pre-dream idle poses must strictly be solitary RPH
        #expect(!collection.rph.isEmpty)
        #expect(collection.rph.allSatisfy { $0.name == "RPH002" && !$0.designated })
        #expect(collection.rph.allSatisfy { !$0.name.starts(with: "RW") })
    }

    /// Tests the complete post-dream transition lifecycle:
    /// Pre-dream idle RPH -> dream completes -> wakeAnimations (RPH_To_BP*) -> JumpGraph routes cleanly back to BP.
    @Test func testPostDreamTransitionFlow() {
        let files = [
            rphLoopMov, rph002Mov,
            rphToBP001_0, rphToBP001_1,
            rphToBP002_0, rphToBP002_1,
            bp001Intro, bp001Intro1,
            bp002Intro, bp002Intro1,
        ]
        let collection = AnimationCollection.from(files: files)

        // 1. Resting roof pose for pre-dream
        let restingRph = collection.rph
        #expect(restingRph.count == 1)
        #expect(restingRph.first?.name == "RPH002")
        #expect(restingRph.first?.designated == false)

        // 2. Post-dream wake transitions (RPH_To_BP001 and RPH_To_BP002)
        let wakeAnims = collection.wakeAnimations
        #expect(wakeAnims.count == 2)
        #expect(wakeAnims.allSatisfy { $0.name == "RPH" && $0.designated })

        // 3. For each wake transition, verify JumpGraph routes cleanly to resting base poses
        for wakeAnim in wakeAnims {
            let destinations = collection.jumpGraph[wakeAnim] ?? []
            #expect(!destinations.isEmpty)
            #expect(destinations.allSatisfy { !$0.designated })
            let destNames = Set(destinations.map(\.name))
            #expect(destNames.contains("BP001") || destNames.contains("BP002"))
        }
    }

    /// Tests the full asset jump graph: verifies that all 91 nodes are mutually connected and reachable,
    /// that SS001 is the only isolated node (0 incoming, 0 outgoing), and that all transitions obey domain rules.
    @Test func testFullGraphConnectivityAndReasonableness() {
        let localDir = URL(fileURLWithPath: "Resources")
        guard let files = try? FileManager.default.contentsOfDirectory(at: localDir, includingPropertiesForKeys: nil)
            .filter({ !$0.lastPathComponent.hasPrefix(".") }), !files.isEmpty else {
            return
        }
        let collection = AnimationCollection.from(files: files)
        let graph = collection.jumpGraph

        // Total graph nodes (all 92 animations)
        #expect(graph.count == 92)

        // 1. Dead ends: exactly 1 node (SS001) has 0 outgoing transitions
        let deadEnds = graph.filter { $0.value.isEmpty }.map(\.key)
        #expect(deadEnds.count == 1)
        #expect(deadEnds.first?.name == "SS001")

        // 2. Orphan nodes: exactly 1 node (SS001) has 0 incoming transitions
        var inDegrees: [Animation: Int] = [:]
        for node in graph.keys { inDegrees[node] = 0 }
        for (_, targets) in graph {
            for target in targets { inDegrees[target, default: 0] += 1 }
        }
        let orphans = inDegrees.filter { $0.value == 0 }.map(\.key)
        #expect(orphans.count == 1)
        #expect(orphans.first?.name == "SS001")

        // 3. Reachability from base sleeping poses (BP001..BP004)
        let basePoses = graph.keys.filter { $0.name.starts(with: "BP") && !$0.designated }
        #expect(basePoses.count == 4)

        var visited: Set<Animation> = Set(basePoses)
        var queue: [Animation] = Array(basePoses)
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for neighbor in graph[current] ?? [] {
                if !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        let unreachableFromBP = Set(graph.keys).subtracting(visited)
        #expect(unreachableFromBP.count == 1)
        #expect(unreachableFromBP.first?.name == "SS001")

        // 4. Returnability: can all nodes return to base sleeping poses (BP001..BP004)?
        var reverseGraph: [Animation: [Animation]] = [:]
        for (node, targets) in graph {
            for target in targets { reverseGraph[target, default: []].append(node) }
        }
        var canReachBP: Set<Animation> = Set(basePoses)
        var revQueue: [Animation] = Array(basePoses)
        while !revQueue.isEmpty {
            let current = revQueue.removeFirst()
            for pred in reverseGraph[current] ?? [] {
                if !canReachBP.contains(pred) {
                    canReachBP.insert(pred)
                    revQueue.append(pred)
                }
            }
        }
        let cannotReachBP = Set(graph.keys).subtracting(canReachBP)
        #expect(cannotReachBP.count == 1)
        #expect(cannotReachBP.first?.name == "SS001")

        // 5. Transition reasonableness rules across the entire graph
        for (node, targets) in graph where node.name != "SS001" {
            // Every non-SS001 node has outgoing transitions
            #expect(!targets.isEmpty)

            // No node transitions into SS001
            #expect(!targets.contains { $0.name == "SS001" })

            // Solitary poses (BP*, RP*) never transition directly to Woodstock (RW*)
            if node.name.starts(with: "BP") || node.name.starts(with: "RP") {
                #expect(!targets.contains { $0.name.starts(with: "RW") })
            }
        }

        // 6. Post-dream wake transitions must strictly route to base sleeping poses
        #expect(collection.wakeAnimations.count == 4)
        for wakeAnim in collection.wakeAnimations {
            #expect(wakeAnim.name == "RPH" && wakeAnim.designated)
            let destinations = graph[wakeAnim] ?? []
            #expect(!destinations.isEmpty)
            #expect(destinations.allSatisfy { $0.name.starts(with: "BP") && !$0.designated })
        }
    }
}
