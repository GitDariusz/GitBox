import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?

    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        heavyImpact.prepare()
        mediumImpact.prepare()
        notificationFeedback.prepare()
    }

    // Gong + mocna wibracja: start rundy
    func playRoundStart() {
        play("gong")
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }

    // Bell + średnia wibracja: koniec rundy, start przerwy
    func playRoundEnd() {
        play("bell2")
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    // Bell x2 + sukces: ukończenie treningu
    func playWorkoutComplete() {
        play("bell2")
        notificationFeedback.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.play("bell3")
        }
    }

    private func play(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("❌ Błąd odtwarzania \(name).mp3: \(error)")
        }
    }
}
