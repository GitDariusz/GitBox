import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // Planuje powiadomienia dla każdej zmiany fazy (używane gdy app idzie w tło)
    func schedulePhaseNotifications(from vm: TimerViewModel) {
        cancelAll()
        var delay: Double = Double(vm.timeRemaining)
        var isBreak = vm.isBreak
        var isPrep = vm.isPreparation
        var round = vm.currentRound
        var index = 0

        while index < 30 {
            let title: String
            let body: String
            let nextDuration: Int
            let done: Bool

            if isPrep {
                title = "🥊 Runda \(round)"
                body = "WALCZ!"
                nextDuration = vm.roundTime
                done = false
                isPrep = false
            } else if isBreak {
                title = "🥊 Runda \(round + 1)"
                body = "WALCZ!"
                nextDuration = vm.roundTime
                done = false
                isBreak = false
                round += 1
            } else if round >= vm.rounds {
                title = "🏆 Trening ukończony!"
                body = "Świetna robota! \(vm.rounds) rund zaliczone."
                nextDuration = 0
                done = true
            } else {
                title = "💧 Przerwa"
                body = "Runda \(round + 1) za \(vm.breakTime)s"
                nextDuration = vm.breakTime
                done = false
                isBreak = true
            }

            schedule(id: "bx_\(index)", title: title, body: body, delay: delay)
            index += 1
            if done { break }
            delay += Double(nextDuration)
        }
    }

    func cancelAll() {
        let ids = (0..<30).map { "bx_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func schedule(id: String, title: String, body: String, delay: Double) {
        guard delay > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
