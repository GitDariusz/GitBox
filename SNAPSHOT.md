# GIT BOXING — SNAPSHOT
*Ostatnia aktualizacja: 2026-05-02*

---

## Lista plików i co robią

### Swift (logika aplikacji)

| Plik | Rola |
|------|------|
| `GIT_BOXING/BoxingTimerApp.swift` | Punkt wejścia aplikacji (`@main`). Uruchamia `ContentView` w `WindowGroup`. |
| `GIT_BOXING/ContentView.swift` | Główny `TabView` z 2 zakładkami: *Trening* i *Historia*. Zawiera też `TimerSetupView`, `FireSettingCard`, `SessionSummaryBar`, `SummaryItem` oraz extension `Color(hex:)`. |
| `GIT_BOXING/TimerView.swift` | Pełnoekranowy widok timera podczas treningu. Obsługuje fazy: przygotowanie (5s) → runda → przerwa → kolejna runda. Zapisuje sesję przez `TrainingStore`. |
| `GIT_BOXING/HistoryView.swift` | Historia treningów. Pokazuje siatką statystyk (`StatsGrid`, `StatCard`) i listę sesji (`SessionRow`). Umożliwia wyczyszczenie historii. |
| `GIT_BOXING/SoundManager.swift` | Singleton do odtwarzania dźwięków MP3 przez `AVFoundation`. Odtwarza `gong.mp3`, `bell2.mp3`, `bell3.mp3`. |
| `GIT_BOXING/TrainingStore.swift` | Model danych (`TrainingSession: Codable`) + singleton `TrainingStore` z persistencją w `UserDefaults`. Oblicza statystyki: totalSessions, totalActiveTime, totalRounds, completedSessions. |
| `GIT_BOXING/Item.swift` | **Nieużywany** — pozostałość po szablonie Xcode (SwiftData `@Model`). Nie jest nigdzie używany w aplikacji. |

### Zasoby

| Zasób | Opis |
|-------|------|
| `Assets.xcassets/bell2.dataset/bell2.mp3` | Dźwięk końca rundy |
| `Assets.xcassets/bell3.dataset/bell3.mp3` | Dźwięk zakończenia treningu |
| `Assets.xcassets/gong.dataset/gong.mp3` | Dźwięk startu rundy / końca przerwy |
| `Assets.xcassets/AppIcon.appiconset/` | Ikona aplikacji 1024×1024 |
| `Assets.xcassets/AccentColor.colorset/` | Kolor akcentu (używany przez `Color("FireRed")` w `ContentView`) |

---

## Aktualny stan funkcji

### Działa
- Konfiguracja treningu: czas rundy (10–600s, krok 10s), przerwa (5–180s, krok 5s), liczba rund (1–20)
- Podsumowanie sesji przed startem (całkowity czas, rundy, czas aktywny)
- Faza przygotowawcza 5 sekund przed pierwszą rundą
- Animowany pierścieniowy timer z progresem
- Zmiana koloru tła w zależności od fazy (żółty = gotowość, niebieski = przerwa, czerwony = runda)
- Dźwięki: gong na start rundy, bell2 na koniec rundy, bell2+bell3 na koniec treningu
- Wyłączenie auto-lock ekranu podczas treningu (`UIApplication.shared.isIdleTimerDisabled = true`)
- Zapis każdej sesji (ukończonej i przerwanej) do `UserDefaults`
- Historia treningów: statystyki zbiorcze + lista sesji z datą, rundy, czas aktywny
- Usuwanie całej historii (z potwierdzeniem)
- Dark mode, motyw czerwono-czarny

### Potencjalne problemy / do weryfikacji
- `Item.swift` importuje `SwiftData` — może powodować ostrzeżenia przy budowaniu, jeśli SwiftData nie jest w pełni skonfigurowane (brak `ModelContainer`). Plik jest niepotrzebny.
- `SoundManager` przechowuje tylko jeden `AVAudioPlayer` — jeśli dwa dźwięki zagrają szybko po sobie (bell2 + bell3 z opóźnieniem 1.5s), drugi nadpisze referencję, ale bell3 jest odtwarzany z opóźnieniem więc jest OK.
- `TimerView` używa `Timer.scheduledTimer` bezpośrednio na main thread — przy nawigacji / tle aplikacja może tracić ticki (brak `BackgroundTask` / `BGTaskScheduler`).
- Brak obsługi trybu tła (trening zatrzyma się gdy aplikacja przejdzie do tła).

---

## Otwarte problemy / TODO

- [ ] **Usunąć `Item.swift`** — niepotrzebny plik po szablonie Xcode
- [ ] **Tryb tła** — timer powinien kontynuować gdy ekran jest zablokowany lub aplikacja w tle (wymaga `AVAudioSession` + `Background Modes` w entitlements)
- [ ] **Wibracje** — dodać `UIImpactFeedbackGenerator` na zmianę fazy
- [ ] **Lokalizacja `FireRed`** — `Color("FireRed")` w `ContentView` zdefiniowany w `AccentColor.colorset`, ale `FireSettingCard` i reszta używa `Color(hex: "FF4500")` — warto ujednolicić
- [ ] **Brak edycji / usuwania pojedynczej sesji** — historia pozwala tylko wyczyścić wszystko
- [ ] **Brak eksportu danych** — historii nie można udostępnić / eksportować
- [ ] **Widget / Live Activity** — brak (przydatny do widoku na ekranie blokady)
- [ ] **Testy jednostkowe** — brak jakichkolwiek testów

---

## Ostatnie zmiany (git log)

| Hash | Opis |
|------|------|
| `3b407c9` | Initial commit - GIT BOXING app (cały obecny kod) |
| `742bee7` | Initial Commit |

---

## Architektura w skrócie

```
BoxingTimerApp
└── ContentView (TabView)
    ├── Tab 0: TimerSetupView
    │   └── fullScreenCover → TimerView
    │       ├── SoundManager.shared (AVFoundation)
    │       └── TrainingStore.shared (UserDefaults) — zapis po zakończeniu
    └── Tab 1: HistoryView
        └── TrainingStore.shared (odczyt)
```

**Persystencja:** `UserDefaults` (klucz `boxing_training_sessions`), dane kodowane jako JSON przez `Codable`.
