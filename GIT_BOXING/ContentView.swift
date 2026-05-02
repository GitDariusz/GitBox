import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerSetupView()
                .tabItem {
                    Label("Trening", systemImage: "figure.boxing")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("Historia", systemImage: "chart.bar.fill")
                }
                .tag(1)
        }
        .accentColor(Color(hex: "FF4500"))
        .preferredColorScheme(.dark)
        .onAppear {
            NotificationManager.shared.requestPermission()
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
    }
}

// MARK: - Timer Setup View
struct TimerSetupView: View {
    @State private var roundTime: Int = 180
    @State private var breakTime: Int = 60
    @State private var rounds: Int = 3
    @State private var showTimerView: Bool = false

    var body: some View {
        ZStack {
            // Tło
            Color.black.edgesIgnoringSafeArea(.all)

            // Dekoracyjne elementy tła
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .position(x: geo.size.width * 0.85, y: -50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.18), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.75)
            }
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 4) {
                        HStack(spacing: 10) {
                            Text("🥊")
                                .font(.system(size: 38))
                            Text("GIT\nBOXING")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(hex: "FF4500")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .multilineTextAlignment(.leading)
                                .lineSpacing(-4)
                        }
                        Text("BOXING TIMER")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "FF4500").opacity(0.8))
                            .kerning(4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 30)

                    // Ustawienia
                    VStack(spacing: 16) {
                        FireSettingCard(
                            title: "CZAS RUNDY",
                            icon: "timer",
                            value: $roundTime,
                            range: 10...600,
                            step: 10,
                            displayFormat: { formatTime($0) }
                        )

                        FireSettingCard(
                            title: "PRZERWA",
                            icon: "pause.circle",
                            value: $breakTime,
                            range: 5...180,
                            step: 5,
                            displayFormat: { formatTime($0) }
                        )

                        FireSettingCard(
                            title: "RUNDY",
                            icon: "repeat",
                            value: $rounds,
                            range: 1...20,
                            step: 1,
                            displayFormat: { "\($0)" }
                        )
                    }
                    .padding(.horizontal, 20)

                    // Podsumowanie sesji
                    SessionSummaryBar(rounds: rounds, roundTime: roundTime, breakTime: breakTime)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Przycisk Start
                    Button(action: { showTimerView = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("ROZPOCZNIJ TRENING")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .kerning(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            ZStack {
                                LinearGradient(
                                    colors: [Color(hex: "FF4500"), Color(hex: "CC1500")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                // Blask
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "FF4500").opacity(0.5), radius: 20, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showTimerView) {
            TimerView(
                roundTime: roundTime,
                breakTime: breakTime,
                rounds: rounds
            ) {
                showTimerView = false
            }
        }
    }

    func formatTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)min" : "\(m):\(String(format: "%02d", s))"
    }
}

// MARK: - Karta ustawień
struct FireSettingCard: View {
    let title: String
    let icon: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let displayFormat: (Int) -> String

    var body: some View {
        HStack {
            // Ikona + tytuł
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "FF4500").opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "FF4500"))
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                    .kerning(1)
            }

            Spacer()

            // Kontrolka
            HStack(spacing: 0) {
                Button(action: {
                    if value > range.lowerBound { value -= step }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(value > range.lowerBound ? .white : Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                }

                Text(displayFormat(value))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 60)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: value)

                Button(action: {
                    if value < range.upperBound { value += step }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(value < range.upperBound ? .white : Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                }
            }
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Pasek podsumowania sesji
struct SessionSummaryBar: View {
    let rounds: Int
    let roundTime: Int
    let breakTime: Int

    var totalSeconds: Int {
        rounds * roundTime + max(0, rounds - 1) * breakTime
    }

    var body: some View {
        HStack {
            SummaryItem(label: "SESJA", value: formatDuration(totalSeconds), icon: "clock.fill")
            Divider().background(Color.white.opacity(0.1)).frame(height: 30)
            SummaryItem(label: "RUNDY", value: "\(rounds)x", icon: "repeat")
            Divider().background(Color.white.opacity(0.1)).frame(height: 30)
            SummaryItem(label: "AKTYWNY", value: formatDuration(rounds * roundTime), icon: "flame.fill")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "FF4500").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "FF4500").opacity(0.2), lineWidth: 1)
                )
        )
    }

    func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)min" : "\(m):\(String(format: "%02d", s))" 
    }
}

struct SummaryItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "FF4500").opacity(0.7))
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color.white.opacity(0.4))
                .kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color hex helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
