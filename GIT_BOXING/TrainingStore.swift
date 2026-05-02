import Foundation
import SwiftUI

// MARK: - Model sesji treningowej
struct TrainingSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let rounds: Int
    let roundTime: Int       // sekundy
    let breakTime: Int       // sekundy
    let completedRounds: Int
    let totalDuration: Int   // sekundy (faktyczny czas)
    let wasCompleted: Bool

    var activeTime: Int { completedRounds * roundTime }
    var breaksTaken: Int { max(0, completedRounds - 1) }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        rounds: Int,
        roundTime: Int,
        breakTime: Int,
        completedRounds: Int,
        totalDuration: Int,
        wasCompleted: Bool
    ) {
        self.id = id
        self.date = date
        self.rounds = rounds
        self.roundTime = roundTime
        self.breakTime = breakTime
        self.completedRounds = completedRounds
        self.totalDuration = totalDuration
        self.wasCompleted = wasCompleted
    }
}

// MARK: - Store treningów (UserDefaults)
class TrainingStore: ObservableObject {
    static let shared = TrainingStore()

    @Published var sessions: [TrainingSession] = []

    private let key = "boxing_training_sessions"

    private init() {
        load()
    }

    func save(session: TrainingSession) {
        sessions.insert(session, at: 0)
        persist()
    }

    func clearAll() {
        sessions = []
        persist()
    }

    // Statystyki
    var totalSessions: Int { sessions.count }
    var totalActiveTime: Int { sessions.reduce(0) { $0 + $1.activeTime } }
    var totalRounds: Int { sessions.reduce(0) { $0 + $1.completedRounds } }
    var completedSessions: Int { sessions.filter { $0.wasCompleted }.count }

    var averageRoundsPerSession: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(totalRounds) / Double(sessions.count)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TrainingSession].self, from: data)
        else { return }
        sessions = decoded
    }
}
