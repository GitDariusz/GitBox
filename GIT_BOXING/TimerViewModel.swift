import SwiftUI

final class TimerViewModel: ObservableObject {
    let roundTime: Int
    let breakTime: Int
    let rounds: Int

    @Published var timeRemaining: Int
    @Published var currentRound: Int = 1
    @Published var isBreak: Bool = false
    @Published var isPreparation: Bool = true
    @Published var timerRunning: Bool = false
    @Published var completedRounds: Int = 0
    @Published var pulse: Bool = false
    @Published var isFinished: Bool = false

    private var timer: Timer?
    private var sessionStartTime: Date = Date()
    private var backgroundEntryDate: Date?
    private var wasRunningBeforeBackground: Bool = false

    init(roundTime: Int, breakTime: Int, rounds: Int) {
        self.roundTime = roundTime
        self.breakTime = breakTime
        self.rounds = rounds
        self.timeRemaining = 5
    }

    // MARK: - Computed

    var phaseColor: Color {
        if isPreparation { return Color(hex: "FFB300") }
        if isBreak { return Color(hex: "1E90FF") }
        return Color(hex: "FF4500")
    }

    var phaseLabel: String {
        if isPreparation { return "GOTOWOŚĆ" }
        if isBreak { return "PRZERWA" }
        return "RUNDA \(currentRound)"
    }

    var phaseIcon: String {
        if isPreparation { return "🔔" }
        if isBreak { return "💧" }
        return "🥊"
    }

    var progress: Double {
        let total: Int
        if isPreparation { total = 5 }
        else if isBreak { total = breakTime }
        else { total = roundTime }
        guard total > 0 else { return 0 }
        return Double(timeRemaining) / Double(total)
    }

    // MARK: - Lifecycle

    func onAppear() {
        sessionStartTime = Date()
        pulse = true
        startPhase()
    }

    func onDisappear() {
        stopTimer()
    }

    // MARK: - Timer control

    func startPhase() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                t.invalidate()
                self.handlePhaseEnd()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerRunning = false
    }

    func togglePause() {
        if timerRunning { stopTimer() } else { startPhase() }
    }

    // MARK: - Phase transitions

    private func handlePhaseEnd() {
        if isPreparation {
            isPreparation = false
            timeRemaining = roundTime
            SoundManager.shared.playRoundStart()
            startPhase()
        } else if isBreak {
            isBreak = false
            currentRound += 1
            timeRemaining = roundTime
            SoundManager.shared.playRoundStart()
            startPhase()
        } else {
            completedRounds += 1
            if currentRound >= rounds {
                SoundManager.shared.playWorkoutComplete()
                saveSession(completed: true)
                withAnimation(.easeIn(duration: 0.5)) { isFinished = true }
            } else {
                SoundManager.shared.playRoundEnd()
                isBreak = true
                timeRemaining = breakTime
                startPhase()
            }
        }
    }

    // MARK: - Background recovery

    func handleBackground() {
        wasRunningBeforeBackground = timerRunning
        backgroundEntryDate = Date()
        if timerRunning {
            NotificationManager.shared.schedulePhaseNotifications(from: self)
            stopTimer()
        }
    }

    func handleForeground() {
        NotificationManager.shared.cancelAll()
        guard let bgDate = backgroundEntryDate, wasRunningBeforeBackground else {
            backgroundEntryDate = nil
            return
        }
        backgroundEntryDate = nil
        let elapsed = Int(Date().timeIntervalSince(bgDate))
        recoverFromElapsed(elapsed)
        if !isFinished { startPhase() }
    }

    // Symuluje przejścia faz które wystąpiły w tle
    private func recoverFromElapsed(_ elapsed: Int) {
        guard elapsed > 0 else { return }
        var remaining = timeRemaining
        var boolIsBreak = isBreak
        var boolIsPrep = isPreparation
        var round = currentRound
        var completed = completedRounds
        var toProcess = elapsed

        while toProcess > 0 {
            if toProcess < remaining {
                remaining -= toProcess
                break
            }
            toProcess -= remaining
            if boolIsPrep {
                boolIsPrep = false
                remaining = roundTime
            } else if boolIsBreak {
                boolIsBreak = false
                round += 1
                remaining = roundTime
            } else {
                completed += 1
                if round >= rounds {
                    isPreparation = false; isBreak = false
                    currentRound = round; completedRounds = completed; timeRemaining = 0
                    saveSession(completed: true)
                    withAnimation(.easeIn(duration: 0.5)) { isFinished = true }
                    return
                }
                boolIsBreak = true
                remaining = breakTime
            }
        }

        isPreparation = boolIsPrep
        isBreak = boolIsBreak
        currentRound = round
        completedRounds = completed
        timeRemaining = remaining
    }

    // MARK: - Persistence

    func saveSession(completed: Bool) {
        let duration = Int(Date().timeIntervalSince(sessionStartTime))
        let session = TrainingSession(
            rounds: rounds,
            roundTime: roundTime,
            breakTime: breakTime,
            completedRounds: completed ? rounds : completedRounds,
            totalDuration: duration,
            wasCompleted: completed
        )
        TrainingStore.shared.save(session: session)
    }
}
