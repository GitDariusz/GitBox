import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?

    func playSound(name: String) {
        guard let soundURL = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("❌ Nie znaleziono pliku \(name).mp3")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default) // 🔊 Wymuszenie dźwięku na głośnikach
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
            print("🔊 Odtwarzanie: \(name).mp3")
        } catch {
            print("❌ Błąd odtwarzania \(name).mp3: \(error.localizedDescription)")
        }
    }
}
