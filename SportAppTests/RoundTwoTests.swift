import XCTest
@testable import SportApp

final class RoundTwoTests: XCTestCase {
    override func tearDown() {
        Catalog.gymScales = [:]
        super.tearDown()
    }

    func testOldMachineDataStillDecodes() throws {
        let json = #"{"name":"Chest press","steps":"25-85 kg","on":true}"#.data(using: .utf8)!
        let m = try JSONDecoder().decode(GymMachine.self, from: json)
        XCTAssertEqual(m.name, "Chest press")
        XCTAssertEqual(m.legacySteps, "25-85 kg")
        XCTAssertEqual(m.stepsText, "25-85 kg")
        XCTAssertTrue(m.on)
    }

    func testMachineRoundTrip() throws {
        var m = GymMachine(brand: "Technogym", name: "Chest press", exercises: ["Chest press machine"], min: 5, max: 100, step: 5, addOn: 2.5)
        m.on = false
        let back = try JSONDecoder().decode(GymMachine.self, from: JSONEncoder().encode(m))
        XCTAssertEqual(back, m)
        XCTAssertEqual(back.stepsText, "5\u{2013}100 kg \u{00B7} stap 5 (+2,5)")
    }

    func testDatabaseHasMainBrandsAndKnownExercises() {
        for b in ["Technogym", "Matrix", "Basic-Fit", "Life Fitness", "Gym80", "Hammer Strength"] {
            XCTAssertTrue(MachineDB.brands.contains(b), b)
        }
        let known = Set(Catalog.names)
        for m in MachineDB.all {
            for e in m.exercises { XCTAssertTrue(known.contains(e), "\(m.id): \(e)") }
            XCTAssertGreaterThan(m.step, 0)
        }
    }

    func testGymMachineStepsOverrideDefaultSteps() {
        let model = AppModel(fileURL: nil)
        let before = Catalog.step("Lat pulldown", weight: 45, dir: 1)
        XCTAssertEqual(before, 50)
        let machine = MachineModel(brand: "Test", series: "", name: "Lat", family: "Machine", kind: .stack,
                                   exercises: ["Lat pulldown"], min: 7, max: 70, step: 7, addOn: nil)
        model.addMachine(machine)
        XCTAssertEqual(Catalog.step("Lat pulldown", weight: 14, dir: 1), 21)
        XCTAssertEqual(Catalog.step("Lat pulldown", weight: 14, dir: -1), 7)
        let id = model.gym.equipment[0].id
        model.toggleMachine(id)
        XCTAssertEqual(Catalog.step("Lat pulldown", weight: 45, dir: 1), 50)
    }

    func testAddMachineOnlyOnceAndRemove() {
        let model = AppModel(fileURL: nil)
        let m = MachineDB.all[0]
        model.addMachine(m)
        model.addMachine(m)
        XCTAssertEqual(model.gym.equipment.count, 1)
        model.removeMachine(model.gym.equipment[0].id)
        XCTAssertTrue(model.gym.equipment.isEmpty)
    }

    func testGymCreateRenameDelete() {
        let model = AppModel(fileURL: nil)
        model.addGym(name: "Basic-Fit Zuid")
        XCTAssertEqual(model.gyms.count, 2)
        XCTAssertEqual(model.gym.name, "Basic-Fit Zuid")
        model.renameGym("Basic-Fit Noord")
        XCTAssertEqual(model.gym.name, "Basic-Fit Noord")
        model.deleteGym(model.gym.id)
        XCTAssertEqual(model.gyms.count, 1)
        model.deleteGym(model.gym.id)
        XCTAssertEqual(model.gyms.count, 1)
    }
}
