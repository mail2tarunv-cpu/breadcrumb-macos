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

    func testRelaunchSameDocumentDoesNotRequireSameTabTitle() {
        let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let original = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Original title",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com/page",
            selectedTabTitle: "Original title",
            selectedTabIndex: 0
        )

        let record = BreadcrumbRecord(
            text: "Return here",
            context: original,
            anchorPoint: .zero
        )

        let relaunched = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Updated title",
            windowFrame: frame,
            processIdentifier: 200,
            windowNumber: 55,
            documentURL: "https://example.com/page",
            selectedTabTitle: "Updated title",
            selectedTabIndex: 2
        )

        XCTAssertTrue(relaunched.matches(record))
    }

    func testRelaunchCanFallBackToSelectedTabTitleWhenURLChanges() {
        let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let original = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Dashboard",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com/old",
            selectedTabTitle: "Project Alpha",
            selectedTabIndex: 0
        )

        let record = BreadcrumbRecord(
            text: "Alpha",
            context: original,
            anchorPoint: .zero
        )

        let relaunched = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Dashboard",
            windowFrame: frame,
            processIdentifier: 200,
            windowNumber: 55,
            documentURL: "https://example.com/new",
            selectedTabTitle: "Project Alpha",
            selectedTabIndex: 0
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
    func testStoreRecoversFromCorruptPrimaryUsingBackup() throws {
        let suiteName = "BreadcrumbTests.Recovery.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = BreadcrumbStore(defaults: defaults)
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: CGRect(x: 0, y: 0, width: 800, height: 600)
        )

        let original = BreadcrumbRecord(
            text: "Recover me",
            context: context,
            anchorPoint: CGPoint(x: 200, y: 180)
        )

        store.save([original])
        defaults.set(Data("not-json".utf8), forKey: "breadcrumb.records.v1")

        let recovered = store.load()

        XCTAssertEqual(recovered, [original])
        XCTAssertEqual(
            try JSONDecoder().decode(
                [BreadcrumbRecord].self,
                from: XCTUnwrap(defaults.data(forKey: "breadcrumb.records.v1"))
            ),
            [original]
        )
    }

    func testSameSessionSameTitleDifferentWindowDoesNotMatch() {
        let frame = CGRect(x: 20, y: 40, width: 900, height: 700)

        let original = ContextSnapshot(
            bundleIdentifier: "com.apple.finder",
            applicationName: "Finder",
            windowTitle: "Downloads",
            windowFrame: frame,
            processIdentifier: 101,
            windowNumber: 10
        )

        let record = BreadcrumbRecord(
            text: "Window-specific",
            context: original,
            anchorPoint: CGPoint(x: 300, y: 300)
        )

        let otherWindow = ContextSnapshot(
            bundleIdentifier: "com.apple.finder",
            applicationName: "Finder",
            windowTitle: "Downloads",
            windowFrame: frame,
            processIdentifier: 101,
            windowNumber: 11
        )

        XCTAssertFalse(otherWindow.matches(record))
    }

    func testRelaunchTitleFallbackRejectsDifferentTabTitle() {
        let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let original = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Dashboard",
            windowFrame: frame,
            processIdentifier: 100,
            windowNumber: 10,
            documentURL: "https://example.com/old",
            selectedTabTitle: "Project Alpha",
            selectedTabIndex: 0
        )

        let record = BreadcrumbRecord(
            text: "Alpha only",
            context: original,
            anchorPoint: CGPoint(x: 420, y: 350)
        )

        let relaunchedDifferentTab = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Dashboard",
            windowFrame: frame,
            processIdentifier: 200,
            windowNumber: 99,
            documentURL: "https://example.com/new",
            selectedTabTitle: "Project Beta",
            selectedTabIndex: 0
        )

        XCTAssertFalse(relaunchedDifferentTab.matches(record))
    }

    func testAnchorStaysRelativeAfterMoveResizeAndDisplayChange() {
        let originalFrame = CGRect(x: 100, y: 100, width: 1000, height: 800)
        let context = ContextSnapshot(
            bundleIdentifier: "com.figma.Desktop",
            applicationName: "Figma",
            windowTitle: "Design File",
            windowFrame: originalFrame,
            displayIdentifier: "display-a"
        )

        let record = BreadcrumbRecord(
            text: "Keep position",
            context: context,
            anchorPoint: CGPoint(x: 850, y: 300)
        )

        XCTAssertEqual(record.relativeX, 0.75, accuracy: 0.0001)
        XCTAssertEqual(record.relativeY, 0.25, accuracy: 0.0001)

        let movedFrame = CGRect(x: -1200, y: 240, width: 800, height: 600)
        let movedPoint = record.anchorPoint(in: movedFrame)

        XCTAssertEqual(movedPoint.x, -600, accuracy: 0.0001)
        XCTAssertEqual(movedPoint.y, 390, accuracy: 0.0001)
    }

    func testAnchorCoordinatesClampToWindowBoundsWhenCreatedOutsideFrame() {
        let frame = CGRect(x: 100, y: 100, width: 600, height: 400)
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: frame
        )

        let record = BreadcrumbRecord(
            text: "Clamp me",
            context: context,
            anchorPoint: CGPoint(x: 900, y: -200)
        )

        XCTAssertEqual(record.relativeX, 1, accuracy: 0.0001)
        XCTAssertEqual(record.relativeY, 0, accuracy: 0.0001)

        let point = record.anchorPoint(in: frame)
        XCTAssertEqual(point.x, frame.maxX, accuracy: 0.0001)
        XCTAssertEqual(point.y, frame.minY, accuracy: 0.0001)
    }
    func testPersistedAnchorIsSanitizedIntoWindowBounds() {
        let frame = CGRect(x: 100, y: 200, width: 600, height: 400)
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document",
            windowFrame: frame
        )

        var record = BreadcrumbRecord(
            text: "Sanitize me",
            context: context,
            anchorPoint: CGPoint(x: 300, y: 300)
        )

        record.relativeX = 4.2
        record.relativeY = -3.0

        let point = record.anchorPoint(in: frame)

        XCTAssertEqual(point.x, frame.maxX, accuracy: 0.0001)
        XCTAssertEqual(point.y, frame.minY, accuracy: 0.0001)

        record.relativeX = .nan
        record.relativeY = .infinity

        let fallbackPoint = record.anchorPoint(in: frame)

        XCTAssertEqual(fallbackPoint.x, frame.midX, accuracy: 0.0001)
        XCTAssertEqual(fallbackPoint.y, frame.midY, accuracy: 0.0001)
    }
    func testBreadcrumbColorPersistsAndLegacyDefaultsToLavender() throws {
        let suiteName = "BreadcrumbTests.Color.\(UUID().uuidString)"
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
            text: "Color me",
            context: context,
            anchorPoint: CGPoint(x: 300, y: 300)
        )
        record.breadcrumbColor = .mint

        store.save([record])
        let loaded = try XCTUnwrap(store.load().first)

        XCTAssertEqual(loaded.breadcrumbColor, .mint)

        var legacy = loaded
        legacy.colorName = nil
        XCTAssertEqual(legacy.breadcrumbColor, .lavender)
    }
    func testDoneStatePersistsThroughStore() throws {
        let suiteName = "BreadcrumbTests.Done.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = BreadcrumbStore(defaults: defaults)
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Project",
            windowFrame: CGRect(x: 0, y: 0, width: 800, height: 600)
        )

        var record = BreadcrumbRecord(
            text: "Finish this",
            context: context,
            anchorPoint: CGPoint(x: 300, y: 300)
        )
        record.completedAt = Date()

        store.save([record])
        let loaded = try XCTUnwrap(store.load().first)

        XCTAssertTrue(loaded.isDone)
        XCTAssertNotNil(loaded.completedAt)
    }

    func testContextGroupPrefersTabThenWindowThenHost() {
        let frame = CGRect(x: 0, y: 0, width: 800, height: 600)

        let tabContext = ContextSnapshot(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari",
            windowTitle: "Window title",
            windowFrame: frame,
            documentURL: "https://example.com/path",
            selectedTabTitle: "Project Alpha"
        )

        let tabRecord = BreadcrumbRecord(
            text: "Tab",
            context: tabContext,
            anchorPoint: .zero
        )
        XCTAssertEqual(tabRecord.contextGroupName, "Project Alpha")

        let windowContext = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Design File",
            windowFrame: frame
        )

        let windowRecord = BreadcrumbRecord(
            text: "Window",
            context: windowContext,
            anchorPoint: .zero
        )
        XCTAssertEqual(windowRecord.contextGroupName, "Design File")
    }
}
