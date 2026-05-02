import SwiftUI

struct TimerView: View {
    let roundTime: Int
    let breakTime: Int
    let rounds: Int
    var onDismiss: () -> Void

    @StateObject private var vm: TimerViewModel
    @ObservedObject private var healthKit = HealthKitManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init(roundTime: Int, breakTime: Int, rounds: Int, onDismiss: @escaping () -> Void) {
        self.roundTime = roundTime
        self.breakTime = breakTime
        self.rounds = rounds
        self.onDismiss = onDismiss
        _vm = StateObject(wrappedValue: TimerViewModel(roundTime: roundTime, breakTime: breakTime, rounds: rounds))
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geo in
                Circle()
                    .fill(RadialGradient(
                        colors: [vm.phaseColor.opacity(0.3), Color.clear],
                        center: .center, startRadius: 0, endRadius: 350
                    ))
                    .frame(width: 700, height: 700)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                    .animation(.easeInOut(duration: 1.0), value: vm.phaseColor)
            }
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {

                // Top bar
                HStack {
                    Button(action: {
                        vm.stopTimer()
                        vm.saveSession(completed: false)
                        onDismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                            Text("ZAKOŃCZ").font(.system(size: 12, weight: .bold)).kerning(1)
                        }
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Kółka rund
                    HStack(spacing: 6) {
                        ForEach(1...rounds, id: \.self) { r in
                            Circle()
                                .fill(r <= vm.completedRounds ? vm.phaseColor : Color.white.opacity(0.15))
                                .frame(width: 10, height: 10)
                                .scaleEffect(r == vm.currentRound && !vm.isBreak && !vm.isPreparation ? 1.3 : 1.0)
                                .animation(.spring(), value: vm.completedRounds)
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.top, 16)

                Spacer()

                // Faza
                VStack(spacing: 8) {
                    Text(vm.phaseIcon).font(.system(size: 44))
                        .scaleEffect(vm.pulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: vm.pulse)

                    Text(vm.phaseLabel)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(vm.phaseColor).kerning(3)
                        .animation(.easeInOut, value: vm.phaseLabel)
                }

                Spacer().frame(height: 30)

                // Ring timer
                ZStack {
                    Circle().stroke(Color.white.opacity(0.06), lineWidth: 12).frame(width: 240, height: 240)
                    Circle()
                        .trim(from: 0, to: vm.progress)
                        .stroke(
                            AngularGradient(
                                colors: [vm.phaseColor.opacity(0.4), vm.phaseColor],
                                center: .center,
                                startAngle: .degrees(-90), endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: vm.progress)

                    VStack(spacing: 2) {
                        Text(formatTime(vm.timeRemaining))
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.spring(response: 0.4), value: vm.timeRemaining)
                        if !vm.isPreparation {
                            Text(vm.isBreak ? "do rundy \(vm.currentRound + 1)" : "rundy \(vm.currentRound)/\(rounds)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                }

                Spacer().frame(height: 24)

                // Live tętno z Apple Watch
                HeartRateDisplay(heartRate: healthKit.currentHeartRate)

                Spacer().frame(height: 26)

                // Pause / play
                Button(action: { vm.togglePause() }) {
                    ZStack {
                        Circle()
                            .fill(vm.timerRunning ? Color.white.opacity(0.1) : vm.phaseColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(
                                vm.timerRunning ? Color.white.opacity(0.15) : vm.phaseColor.opacity(0.4),
                                lineWidth: 1.5
                            ))
                        Image(systemName: vm.timerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(vm.timerRunning ? Color.white.opacity(0.7) : vm.phaseColor)
                    }
                }

                Spacer().frame(height: 40)
            }

            // Ekran ukończenia
            if vm.isFinished {
                CompletionOverlay(rounds: rounds)
                    .transition(.opacity)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            vm.onAppear()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            vm.onDisappear()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background: vm.handleBackground()
            case .active:     vm.handleForeground()
            default: break
            }
        }
        .onChange(of: vm.isFinished) { finished in
            if finished {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { onDismiss() }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)" }
        return "\(m):\(String(format: "%02d", s))"
    }
}

// MARK: - Live tętno

struct HeartRateDisplay: View {
    let heartRate: Double?

    var body: some View {
        Group {
            if let hr = heartRate {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .symbolEffect(.pulse)
                    Text("\(Int(hr))")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    Text("BPM")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.4))
                        .kerning(1)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text("Brak danych z Watch")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.2))
                }
            }
        }
        .animation(.easeInOut, value: heartRate)
    }
}

// MARK: - Ekran ukończenia

struct CompletionOverlay: View {
    let rounds: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("🏆").font(.system(size: 80))
                Text("TRENING\nUKOŃCZONY!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("\(rounds) \(rounds == 1 ? "runda" : rounds < 5 ? "rundy" : "rund") ukończone")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "FF4500"))
            }
        }
    }
}
