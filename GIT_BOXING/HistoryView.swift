import SwiftUI

struct HistoryView: View {
    @ObservedObject private var store = TrainingStore.shared
    @State private var showClearConfirm = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            // Tło glow
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FF4500").opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .position(x: geo.size.width * 0.1, y: 0)
            }
            .edgesIgnoringSafeArea(.all)

            if store.sessions.isEmpty {
                EmptyHistoryView()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Nagłówek
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("HISTORIA")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("TWOICH TRENINGÓW")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "FF4500").opacity(0.8))
                                    .kerning(3)
                            }
                            Spacer()
                            Button(action: { showClearConfirm = true }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.3))
                                    .padding(10)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                        // Karty statystyk
                        StatsGrid(store: store)
                            .padding(.horizontal, 20)

                        // Separator
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                            Text("SESJE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.3))
                                .kerning(2)
                                .padding(.horizontal, 10)
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                        // Lista sesji
                        LazyVStack(spacing: 10) {
                            ForEach(Array(store.sessions.enumerated()), id: \.element.id) { index, session in
                                SessionRow(session: session, index: index + 1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .confirmationDialog("Usunąć wszystkie treningi?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Usuń wszystko", role: .destructive) {
                withAnimation { store.clearAll() }
            }
            Button("Anuluj", role: .cancel) {}
        }
    }
}

// MARK: - Siatka statystyk
struct StatsGrid: View {
    let store: TrainingStore

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatCard(
                    value: "\(store.totalSessions)",
                    label: "Sesje",
                    icon: "figure.boxing",
                    color: Color(hex: "FF4500")
                )
                StatCard(
                    value: formatDuration(store.totalActiveTime),
                    label: "Aktywny czas",
                    icon: "flame.fill",
                    color: Color(hex: "FF6B00")
                )
            }
            HStack(spacing: 10) {
                StatCard(
                    value: "\(store.totalRounds)",
                    label: "Rundy łącznie",
                    icon: "repeat",
                    color: Color(hex: "FF3D00")
                )
                StatCard(
                    value: "\(store.completedSessions)",
                    label: "Ukończone",
                    icon: "checkmark.seal.fill",
                    color: Color(hex: "FF8C00")
                )
            }
        }
    }

    func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)min"
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Wiersz sesji
struct SessionRow: View {
    let session: TrainingSession
    let index: Int

    var body: some View {
        HStack(spacing: 14) {
            // Numer + status
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(session.wasCompleted ? Color(hex: "FF4500").opacity(0.15) : Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                Text(session.wasCompleted ? "✓" : "~")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(session.wasCompleted ? Color(hex: "FF4500") : Color.white.opacity(0.3))
            }

            // Szczegóły
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(formatDate(session.date))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if session.wasCompleted {
                        Text("UKOŃCZONY")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Color(hex: "FF4500"))
                            .kerning(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FF4500").opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text("\(session.completedRounds)/\(session.rounds) rund • \(session.roundTime)s/runda • \(session.breakTime)s przerwa")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }

            Spacer()

            // Czas
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.activeTime))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "FF4500"))
                Text("aktywny")
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Dzisiaj, \(timeString(date))" }
        if cal.isDateInYesterday(date) { return "Wczoraj, \(timeString(date))" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, HH:mm"
        formatter.locale = Locale(identifier: "pl_PL")
        return formatter.string(from: date)
    }

    func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)min" : "\(m):\(String(format: "%02d", s))"
    }
}

// MARK: - Brak historii
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🥊")
                .font(.system(size: 64))
                .opacity(0.4)
            Text("Brak treningów")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(Color.white.opacity(0.4))
            Text("Twoja historia pojawi się\npo pierwszym treningu")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
    }
}
