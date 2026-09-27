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

    func testContextMatchingUsesBundleAndWindowTitle() {
        let context = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: "Document A",
            windowFrame: nil
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
            windowFrame: nil
        )

        XCTAssertFalse(differentWindow.matches(record))
    }

    func testContextFallsBackToAppWhenWindowTitleUnavailable() {
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

        let anotherUntitledContext = ContextSnapshot(
            bundleIdentifier: "com.test.app",
            applicationName: "Test",
            windowTitle: nil,
            windowFrame: nil
        )

        XCTAssertTrue(anotherUntitledContext.matches(record))
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
            windowFrame: nil
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
