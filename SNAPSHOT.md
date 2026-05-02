# GIT BOXING — SNAPSHOT
*Ostatnia aktualizacja: 2026-05-02*

---

## Lista plików i co robią

### Swift (logika aplikacji)

| Plik | Rola |
|------|------|
| `BoxingTimerApp.swift` | Punkt wejścia (`@main`). Prosi o pozwolenie na powiadomienia przy starcie. |
| `ContentView.swift` | Główny `TabView` (Trening / Historia) + `TimerSetupView` + `FireSettingCard` + `SessionSummaryBar` + `Color(hex:)` extension. |
| `TimerView.swift` | Pełnoekranowy widok timera — **tylko UI**, logika w `TimerViewModel`. Obsługuje `scenePhase` do background recovery. Pokazuje `CompletionOverlay` po ukończeniu. |
| `TimerViewModel.swift` | **Cała logika timera**: fazy (gotowość/runda/przerwa), background recovery (`recoverFromElapsed`), zapis sesji, obsługa `handleBackground/handleForeground`. |
| `NotificationManager.swift` | Singleton `UNUserNotificationCenter`. Planuje powiadomienie dla każdej zmiany fazy gdy app idzie w tło (maks 30 notyfikacji). |
| `SoundManager.swift` | Singleton `AVAudioPlayer` + `UIImpactFeedbackGenerator`. Metody: `playRoundStart()` (gong + heavy haptic), `playRoundEnd()` (bell + medium haptic), `playWorkoutComplete()` (bell×2 + success haptic). |
| `TrainingStore.swift` | Model `TrainingSession: Codable` + singleton store z persistencją w `UserDefaults`. |
| `HistoryView.swift` | Historia i statystyki zbiorcze. |
| `Item.swift` | Pusty plik (usunięto SwiftData `@Model` — był nieużywany). |

### Zasoby

| Zasób | Opis |
|-------|------|
| `Assets.xcassets/bell2.dataset/bell2.mp3` | Dźwięk końca rundy |
| `Assets.xcassets/bell3.dataset/bell3.mp3` | Dźwięk zakończenia treningu |
| `Assets.xcassets/gong.dataset/gong.mp3` | Dźwięk startu rundy / końca przerwy |
| `Assets.xcassets/AppIcon.appiconset/` | Ikona aplikacji |

---

## Architektura

```
BoxingTimerApp
├── init() → NotificationManager.requestPermission()
└── ContentView (TabView)
    ├── Tab 0: TimerSetupView
    │   └── fullScreenCover → TimerView
    │       ├── @StateObject TimerViewModel  ← cała logika timera
    │       │   ├── Timer.scheduledTimer
    │       │   ├── handleBackground() → NotificationManager.schedulePhaseNotifications()
    │       │   ├── handleForeground() → recoverFromElapsed() + cancelAll()
    │       │   └── TrainingStore.save()
    │       ├── SoundManager.shared  ← dźwięki + haptyki
    │       └── @Environment(\.scenePhase) → handleBackground/handleForeground
    └── Tab 1: HistoryView
        └── TrainingStore.shared (odczyt)
```

**Persystencja:** `UserDefaults` (klucz `boxing_training_sessions`), JSON przez `Codable`.

---

## Aktualny stan funkcji

### Działa / zaimplementowane
- Konfiguracja treningu: czas rundy (10–600s), przerwa (5–180s), liczba rund (1–20)
- Faza przygotowawcza 5s + animowany ring timer + zmiana koloru tła z fazą
- **Background recovery**: gdy app jest w tle, po powrocie timer odtwarza wszystkie przejścia faz które minęły
- **Lokalne powiadomienia**: gdy app idzie w tło, planowane są notyfikacje dla każdej zmiany fazy (gong/bell w powiadomieniach)
- **Haptic feedback**: heavy impact na start rundy, medium na koniec rundy, `.success` na ukończenie treningu
- Ekran ukończenia treningu (`CompletionOverlay`) po ostatniej rundzie
- Zapis każdej sesji (ukończonej i przerwanej) do `UserDefaults`
- Historia z statystykami zbiorczymi, usuwanie historii
- Auto-lock wyłączony podczas treningu
- Dark mode, motyw czerwono-czarny

### Otwarte problemy / TODO
- [ ] **Pełne tło** — background recovery działa przez timestamp, ale Timer jest zatrzymany gdy ekran jest zablokowany. Dla ciągłego działania potrzebny entitlement `UIBackgroundModes: audio` + ciągła sesja AVAudioSession (silent looping). Obecne rozwiązanie: powiadomienia jako fallback.
- [ ] **Wibracje bez dźwięku** — `UIImpactFeedbackGenerator` działa tylko gdy app jest aktywny (nie w tle)
- [ ] **Usuwanie pojedynczej sesji** — historia pozwala tylko wyczyścić wszystko
- [ ] **Eksport danych** — brak
- [ ] **Widget / Live Activity** — brak
- [ ] **Testy jednostkowe** — brak (`TimerViewModel` jest teraz testowalny)

---

## Ostatnie zmiany

| Hash | Opis |
|------|------|
| (pending) | Must-have refactor: TimerViewModel, NotificationManager, haptics, background recovery |
| `3b407c9` | Initial commit - GIT BOXING app |
| `742bee7` | Initial Commit |
