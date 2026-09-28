import XCTest
@testable import Breadcrumb

final class BreadcrumbTests: XCTestCase {
    func testRelativeAnchorRoundTrip() {
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: CGRect(x: 100, y: 200, width: 1000, height: 800)
        )

        let record = BreadcrumbRecord(
            text: "Remember this",
            context: context,
            anchorPoint: CGPoint(x: 600, y: 600)
        )

        XCTAssertEqual(record.relativeX, 0.5, accuracy: 0.0001)
        XCTAssertEqual(record.relativeY, 0.5, accuracy: 0.0001)

        let resizedFrame = CGRect(x: 50, y: 80, width: 500, height: 400)
        let point = record.anchorPoint(in: resizedFrame)

        XCTAssertEqual(point.x, 300, accuracy: 0.0001)
        XCTAssertEqual(point.y, 280, accuracy: 0.0001)
    }

    func testContextMatchingUsesExactWindowTitleWithoutDocumentURL() {
        let frame = CGRect(x: 10, y: 10, width: 800, height: 600)

        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document A",
            windowFrame: frame
        )

        let record = BreadcrumbRecord(
            text: "Thought",
            context: context,
            anchorPoint: .zero
        )

        XCTAssertTrue(context.matches(record))

        let differentWindow = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document B",
            windowFrame: frame
        )

        XCTAssertFalse(differentWindow.matches(record))
    }

    func testContextDoesNotFallBackToAppOnly() {
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: nil,
            windowFrame: nil
        )

        let record = BreadcrumbRecord(
            text: "Thought",
            context: context,
            anchorPoint: .zero
        )

        XCTAssertFalse(context.hasStableIdentity)
        XCTAssertFalse(record.hasStableContext)
        XCTAssertFalse(context.matches(record))
    }

    func testBrowserDocumentURLSeparatesTabs() {
        let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let firstTab = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Example",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com/one",
            selectedTabTitle: "One",
            selectedTabIndex: 0
        )

        let record = BreadcrumbRecord(
            text: "Only on tab one",
            context: firstTab,
            anchorPoint: CGPoint(x: 400, y: 300)
        )

        let secondTab = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Example",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com/two",
            selectedTabTitle: "Two",
            selectedTabIndex: 1
        )

        XCTAssertTrue(firstTab.matches(record))
        XCTAssertFalse(secondTab.matches(record))
    }

    func testSameURLDuplicateTabsUseTabIndexWithinSession() {
        let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let firstTab = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Same page",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com",
            selectedTabTitle: "Same page",
            selectedTabIndex: 0
        )

        let record = BreadcrumbRecord(
            text: "Tab zero",
            context: firstTab,
            anchorPoint: .zero
        )

        let duplicateTab = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Same page",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com",
            selectedTabTitle: "Same page",
            selectedTabIndex: 1
        )

        XCTAssertFalse(duplicateTab.matches(record))
    }

    func testPersistedContextMatchesAfterProcessRelaunch() {
        let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let original = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Example",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com",
            selectedTabTitle: "Example",
            selectedTabIndex: 0
        )

        let record = BreadcrumbRecord(
            text: "Return here",
            context: original,
            anchorPoint: CGPoint(x: 400, y: 300)
        )

        let relaunched = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Example",
            windowFrame: frame,
            processIdentifier: 200,
            windowNumber: 55,
            documentURL: "https://example.com",
            selectedTabTitle: "Example",
            selectedTabIndex: 3
        )

        XCTAssertTrue(relaunched.matches(record))
    }

    func testSnoozeStateRoundTripsThroughStore() {
        let suiteName = "BreadcrumbTests.Snooze.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = BreadcrumbStore(defaults: defaults)
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: CGRect(x: 0, y: 0, width: 800, height: 600)
        )

        var record = BreadcrumbRecord(
            text: "Later",
            context: context,
            anchorPoint: .zero
        )
        record.snoozedUntil = Date().addingTimeInterval(3600)

        store.save([record])
        let loaded = store.load()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.snoozedUntil, record.snoozedUntil)
        XCTAssertTrue(loaded.first?.isSnoozed == true)
    }

    func testMinimizedContextNeverMatches() {
        let frame = CGRect(x: 0, y: 0, width: 900, height: 600)

        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: frame
        )

        let record = BreadcrumbRecord(
            text: "Hidden while minimized",
            context: context,
            anchorPoint: .zero
        )

        let minimized = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: frame,
            isMinimized: true
        )

        XCTAssertFalse(minimized.matches(record))
    }

    func testStoreRoundTrip() {
        let suiteName = "BreadcrumbTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = BreadcrumbStore(defaults: defaults)
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            documentURL: "https://example.com",
            selectedTabTitle: "Example",
            selectedTabIndex: 2,
            displayIdentifier: "1"
        )

        let record = BreadcrumbRecord(
            text: "Persist me",
            context: context,
            anchorPoint: CGPoint(x: 10, y: 20)
        )

        store.save([record])
        let loaded = store.load()

        XCTAssertEqual(loaded, [record])
    }
}
