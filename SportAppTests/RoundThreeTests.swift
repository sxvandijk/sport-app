import XCTest
@testable import SportApp

final class RoundThreeTests: XCTestCase {
    func testRechteStangTeltEenKeer() {
        XCTAssertFalse(Catalog.autoTwoSides("Cable fly", acc: "Rechte stang"))
        XCTAssertFalse(Catalog.autoTwoSides("Cable fly", acc: "V-stang"))
        XCTAssertFalse(Catalog.autoTwoSides("Cable fly", acc: "Touw"))
        XCTAssertTrue(Catalog.autoTwoSides("Cable fly", acc: "Losse handgreep"))
        XCTAssertTrue(Catalog.autoTwoSides("Dumbbell bench press", acc: nil))
    }

    func testVolumeVanEenSetMetRechteStang() {
        let set = LiveSet(type: .work, w: 25, r: 12)
        XCTAssertEqual(set.volume(twoSides: false), 300)
        XCTAssertEqual(set.volume(twoSides: true), 600)
    }

    func testLinksEnRechtsAppartTeltBeideKanten() {
        let set = LiveSet(type: .work, w: 10, r: 8, r2: 7)
        XCTAssertEqual(set.volume(twoSides: false), 150)
    }

    func testOneArmStaatStandaardOpLinksEnRechtsApart() {
        let ex = LiveSession.makeExercise(name: "Cable One Arm Tricep Extension", group: 0, plan: nil)
        XCTAssertEqual(ex.uni, true)
        XCTAssertFalse(ex.doubles)
        XCTAssertTrue(ex.sets.filter { $0.type != .warmup }.allSatisfy { $0.r2 != nil })
    }
}
