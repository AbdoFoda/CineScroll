import SnapshotTesting
import SwiftUI
import UIKit
import XCTest
@testable import CineScroll

/// Shared snapshot configuration for deterministic SwiftUI renders.
@MainActor
class SnapshotTestCase: XCTestCase {
  override func invokeTest() {
    setenv("SNAPSHOT_TESTING", "1", 1)
    if let record = Self.snapshotRecordMode {
      withSnapshotTesting(record: record) {
        super.invokeTest()
      }
    } else {
      super.invokeTest()
    }
  }

  override func setUp() {
    super.setUp()
    // XCTest always invokes setUp on the main thread; assumeIsolated is a safe assertion here.
    MainActor.assumeIsolated { UIView.setAnimationsEnabled(false) }
  }

  // nonisolated: only reads ProcessInfo (Sendable) so no main-actor access is needed.
  private nonisolated static var snapshotRecordMode: SnapshotTestingConfiguration.Record? {
    if ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" {
      return .all
    }
    #if RECORD_SNAPSHOTS
    return .all
    #endif
    // Default: auto-record a snapshot the first time it is seen (no reference on disk).
    // Existing references are always compared normally. regressions still fail.
    return .missing
  }

  func assertCineSnapshot<V: View>(
    of view: V,
    named name: String,
    size: CGSize,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    let root = view
      .environment(\.useSnapshotPlaceholders, true)
      .frame(width: size.width, height: size.height)

    let host = UIHostingController(rootView: root)
    host.view.bounds = CGRect(origin: .zero, size: size)
    host.view.backgroundColor = .systemBackground
    host.overrideUserInterfaceStyle = name == "dark" ? .dark : .light
    host.view.layoutIfNeeded()

    let traits = UITraitCollection(userInterfaceStyle: name == "dark" ? .dark : .light)
    assertSnapshot(
      of: host,
      as: .image(size: size, traits: traits),
      named: name,
      file: file,
      testName: testName,
      line: line
    )
  }

  func assertCineColorSchemeSnapshots<V: View>(
    of view: V,
    size: CGSize,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    assertCineSnapshot(
      of: view.preferredColorScheme(.light),
      named: "light",
      size: size,
      file: file,
      testName: testName,
      line: line
    )
    assertCineSnapshot(
      of: view.preferredColorScheme(.dark),
      named: "dark",
      size: size,
      file: file,
      testName: testName,
      line: line
    )
  }
}

enum SnapshotSize {
  static let phone = CGSize(width: 393, height: 852)
  static let movieCard = CGSize(width: 177, height: 268)
  static let suggestionRow = CGSize(width: 360, height: 62)
  static let errorPanel = CGSize(width: 393, height: 320)
  static let searchPanel = CGSize(width: 393, height: 360)
  static let detailPanel = CGSize(width: 393, height: 720)
  static let detailLoading = CGSize(width: 393, height: 400)
  static let gridPanel = CGSize(width: 393, height: 520)
  static let fullGridPanel = CGSize(width: 393, height: 780)
  static let loadingGrid = CGSize(width: 393, height: 560)
  static let recentChips = CGSize(width: 393, height: 120)
  static let loadingMore = CGSize(width: 393, height: 80)
  static let nowPlayingScreen = CGSize(width: 393, height: 640)
  static let searchLoading = CGSize(width: 393, height: 200)
}
