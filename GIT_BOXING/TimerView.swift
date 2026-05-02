import SwiftUI

struct TimerView: View {
    let roundTime: Int
    let breakTime: Int
    let rounds: Int
    var onDismiss: () -> Void

    @State private var timeRemaining: Int
    @State private var currentRound: Int = 1
    @State private var isBreak: Bool = false
    @State private var timerRunning: Bool = false
    @State private var timer: Timer?
    @State private var isPreparation: Bool = true
    @State private var sessionStartTime: Date = Date()
    @State private var completedRounds: Int = 0
    @State private var pulse: Bool = false

    @StateObject private var store = TrainingStore.shared

    init(roundTime: Int, breakTime: Int, rounds: Int, onDismiss: @escaping () -> Void) {
        self.roundTime = roundTime
        self.breakTime = breakTime
        self.rounds = rounds
        self.onDismiss = onDismiss
        _timeRemaining = State(initialValue: 5)
    }

    // Kolor fazy
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

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            // Glowy tła - zmienia się z fazą
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 350
                        )
                    )
                    .frame(width: 700, height: 700)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                    .animation(.easeInOut(duration: 1.0), value: phaseColor)
            }
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {

                // Top bar
                HStack {
                    Button(action: {
                        stopTimer()
                        saveSessionAndDismiss(completed: false)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                            Text("ZAKOŃCZ")
                                .font(.system(size: 12, weight: .bold))
                                .kerning(1)
                        }
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Licznik rund w kółkach
                    HStack(spacing: 6) {
                        ForEach(1...rounds, id: \.self) { r in
                            Circle()
                                .fill(r <= completedRounds ? phaseColor : Color.white.opacity(0.15))
                                .frame(width: 10, height: 10)
                                .scaleEffect(r == currentRound && !isBreak && !isPreparation ? 1.3 : 1.0)
                                .animation(.spring(), value: completedRounds)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Faza
                VStack(spacing: 8) {
                    Text(phaseIcon)
                        .font(.system(size: 44))
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulse)

                    Text(phaseLabel)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(phaseColor)
                        .kerning(3)
                        .animation(.easeInOut, value: phaseLabel)
                }

                Spacer().frame(height: 30)

                // Duży timer z pierścieniem
                ZStack {
                    // Zewnętrzny pierścień tło
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 12)
                        .frame(width: 240, height: 240)

                    // Postęp
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [phaseColor.opacity(0.4), phaseColor],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)

                    // Czas
                    VStack(spacing: 2) {
                        Text(formatTime(timeRemaining))
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.spring(response: 0.4), value: timeRemaining)

                        if !isPreparation {
                            Text(isBreak ? "do rundy \(currentRound + 1)" : "rundy \(currentRound)/\(rounds)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                }

                Spacer().frame(height: 50)

                // Przycisk pauzy
                Button(action: {
                    if timerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(timerRunning ? Color.white.opacity(0.1) : phaseColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(timerRunning ? Color.white.opacity(0.15) : phaseColor.opacity(0.4), lineWidth: 1.5)
                            )

                        Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(timerRunning ? Color.white.opacity(0.7) : phaseColor)
                    }
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            sessionStartTime = Date()
            startTimer()
            pulse = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            stopTimer()
        }
    }

    // MARK: - Timer logic

    func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                t.invalidate()
                handlePhaseEnd()
            }
        }
    }

    func handlePhaseEnd() {
        if isPreparation {
            isPreparation = false
            timeRemaining = roundTime
            SoundManager.shared.playSound(name: "gong")
            startTimer()

        } else if isBreak {
            isBreak = false
            currentRound += 1
            timeRemaining = roundTime
            SoundManager.shared.playSound(name: "gong")
            startTimer()

        } else {
            // Koniec rundy
            completedRounds += 1

            if currentRound >= rounds {
                // Trening zakończony!
                SoundManager.shared.playSound(name: "bell2")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    SoundManager.shared.playSound(name: "bell3")
                    stopTimer()
                    saveSessionAndDismiss(completed: true)
                }
            } else {
                SoundManager.shared.playSound(name: "bell2")
                isBreak = true
                timeRemaining = breakTime
                startTimer()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timerRunning = false
    }

    func saveSessionAndDismiss(completed: Bool) {
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
        onDismiss()
    }

    func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)" }
        return "\(m):\(String(format: "%02d", s))"
    }
}
