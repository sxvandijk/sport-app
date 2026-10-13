import Foundation
import Combine   // nodig voor ObservableObject (met alleen Foundation: "Cannot find type 'ObservableObject'")

/// Alles wat bewaard wordt, in één JSON-bestand.
/// `version` is bedoeld voor latere migraties wanneer het formaat verandert.
struct AppData: Codable {
    /// Versie 2: SetKind, schema's (`programs`) en `settings`. Een bestand uit stap 1 is niet leesbaar en wordt bewaard als `.broken`.
    static let currentVersion = 2

    var version: Int
    var exercises: [Exercise]
    var gyms: [GymProfile]
    var templates: [WorkoutTemplate]
    var programs: [Program]
    var settings: UserSettings
    var history: [ActiveWorkoutSession]
    /// De lopende workout. Wordt na elke wijziging bewaard, zodat je na een crash kunt hervatten.
    var activeSession: ActiveWorkoutSession?
}

/// Opslag en toegangspunt voor de app. Bewust simpel: Codable + JSON-bestand.
/// Later te vervangen door Core Data zonder dat de rest van de app verandert, want de rest praat alleen met deze klasse.
final class WorkoutStore: ObservableObject {
    private(set) var data: AppData
    private(set) var library: ExerciseLibrary

    private let fileURL: URL?
    private let ioQueue = DispatchQueue(label: "WorkoutStore.io", qos: .utility)

    /// - Parameters:
    ///   - fileURL: Waar de data staat. `nil` = alleen in het geheugen (handig voor tests/previews).
    ///   - seed: Startdata als er nog niets bewaard is.
    init(fileURL: URL? = WorkoutStore.defaultFileURL(), seed: AppData = MockData.appData()) {
        self.fileURL = fileURL
        let initial: AppData
        var seeded = false
        if let url = fileURL, let loaded = WorkoutStore.load(from: url) {
            initial = loaded
        } else {
            initial = seed
            seeded = true
        }
        self.data = initial
        self.library = ExerciseLibrary(initial.exercises)
        if seeded { save() }
    }

    // MARK: - Opvragen

    var templates: [WorkoutTemplate] { data.templates }
    var activeSession: ActiveWorkoutSession? { data.activeSession }
    var history: WorkoutHistory { WorkoutHistory(sessions: data.history) }

    var settings: UserSettings { data.settings }
    var programs: [Program] { data.programs }

    var activeGym: GymProfile? {
        data.gyms.first { $0.id == data.settings.currentGymID } ?? data.gyms.first
    }

    var currentProgram: Program? {
        data.programs.first { $0.id == data.settings.currentProgramID } ?? data.programs.first
    }

    func template(withID id: UUID) -> WorkoutTemplate? {
        data.templates.first { $0.id == id }
    }

    /// Wijzigt de instellingen en bewaart ze direct.
    func updateSettings(_ change: (inout UserSettings) -> Void) {
        change(&data.settings)
        save()
        objectWillChange.send()
    }

    func gym(withID id: UUID?) -> GymProfile? {
        guard let id = id else { return nil }
        return data.gyms.first { $0.id == id }
    }

    // MARK: - Workout starten en afronden

    func startSession(template: WorkoutTemplate?) {
        let session = ActiveWorkoutSession.make(from: template, gym: activeGym, library: library)
        data.activeSession = session
        save()
        objectWillChange.send()
    }

    /// Wordt na elke wijziging in een lopende workout aangeroepen. Geen `objectWillChange`,
    /// zodat het startscherm niet bij elke set opnieuw tekent.
    func persist(activeSession session: ActiveWorkoutSession) {
        data.activeSession = session
        save()
    }

    func finishActiveSession(_ session: ActiveWorkoutSession) {
        var finished = session
        finished.endedAt = Date()
        data.history.append(finished)
        data.activeSession = nil
        save()
        objectWillChange.send()
    }

    func discardActiveSession() {
        data.activeSession = nil
        save()
        objectWillChange.send()
    }

    // MARK: - Bestand

    func save() {
        guard let url = fileURL else { return }
        let snapshot = data
        ioQueue.async {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let raw = try encoder.encode(snapshot)
                try raw.write(to: url, options: .atomic)
            } catch {
                print("⚠️ Opslaan mislukt: \(error)")
            }
        }
    }

    /// Wacht tot alle lopende schrijfopdrachten klaar zijn. Alleen nodig in tests.
    func waitUntilSaved() {
        ioQueue.sync {}
    }

    private static func load(from url: URL) -> AppData? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let raw = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AppData.self, from: raw)
        } catch {
            // Nooit stilletjes overschrijven: bewaar het onleesbare bestand ernaast.
            let stamp = Int(Date().timeIntervalSince1970)
            let backup = url.deletingPathExtension().appendingPathExtension("broken-\(stamp).json")
            try? FileManager.default.moveItem(at: url, to: backup)
            print("⚠️ Data niet leesbaar, bewaard als \(backup.lastPathComponent): \(error)")
            return nil
        }
    }

    static func defaultFileURL() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let directory = base.appendingPathComponent("SportApp", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("appdata.json")
    }
}
