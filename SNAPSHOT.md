# GIT BOXING — SNAPSHOT
*Ostatnia aktualizacja: 2026-05-02*

---

## Lista plików i co robią

| Plik | Rola |
|------|------|
| `BoxingTimerApp.swift` | Punkt wejścia `@main`. |
| `ContentView.swift` | TabView (Trening / Historia) + `TimerSetupView` + komponenty UI. Prosi o uprawnienia HealthKit i Notifications w `onAppear`. |
| `TimerView.swift` | Pełnoekranowy timer — czysty View. Live tętno z Apple Watch (`HeartRateDisplay`), `CompletionOverlay` po ukończeniu, scenePhase onChange. |
| `TimerViewModel.swift` | Cała logika: fazy, background recovery, zapis sesji. Wywołuje HealthKit start/stop. |
| `HistoryView.swift` | `List` z swipe-to-delete per sesja. Siatka statystyk ze zbiorczym tętnem. `SessionRow` wyświetla avg/max HR jeśli dostępne z Watch. |
| `HealthKitManager.swift` | Singleton HealthKit. `startWorkout()` → `HKWorkoutBuilder` typ `.boxing`. `finishWorkout()` async → zapisuje trening do Health app + zwraca avg/max HR z Watch. Live HR przez `HKObserverQuery`. |
| `NotificationManager.swift` | Planuje `UNUserNotification` dla każdej zmiany fazy w tle. |
| `SoundManager.swift` | AVAudioPlayer + `UIImpactFeedbackGenerator` (heavy/medium/success). |
| `TrainingStore.swift` | `TrainingSession: Codable` z polami `avgHeartRate`, `maxHeartRate`. Metody: `save`, `update`, `remove(at:)`, `clearAll`. |
| `GIT_BOXING.entitlements` | HealthKit entitlement (`com.apple.developer.healthkit`). |
| `Item.swift` | Pusty plik (nieużywany). |

---

## Architektura

```
BoxingTimerApp
└── ContentView (TabView)
    ├── Tab 0: TimerSetupView → fullScreenCover → TimerView
    │   ├── @StateObject TimerViewModel  ← logika
    │   │   ├── HealthKitManager.startWorkout() / finishWorkout()
    │   │   ├── NotificationManager (background notifications)
    │   │   └── TrainingStore.save() + update()
    │   └── @ObservedObject HealthKitManager ← live HR display
    └── Tab 1: HistoryView
        └── TrainingStore.shared (List + onDelete)
```

**HealthKit flow:**
1. `ContentView.onAppear` → `requestAuthorization()` (dialog jednorazowy)
2. `TimerViewModel.onAppear` → `startWorkout()` → HKWorkoutBuilder typ `.boxing` + HKObserverQuery dla live HR
3. Trening kończy się → `saveSession()` → `finishWorkout()` async → zapisuje do Health.app → pobiera avg/max HR → `TrainingStore.update()`
4. Historii sesja pokazuje tętno jeśli Watch je zmierzył

**Dane z Apple Watch:**
- Live HR podczas treningu: `HKObserverQuery` (aktualizuje się gdy Watch wyśle nową próbkę, co ~5-10 min w trybie normalnym)
- Post-workout HR: `HKStatisticsQuery` za cały czas trwania treningu
- Trening zapisany w aplikacji Fitness/Zdrowie i liczy się do kółek aktywności

---

## Stan funkcji

### Działa (zaimplementowane)
- Timer z fazami: gotowość → runda → przerwa → ...
- Background recovery (timestamp + local notifications)
- Haptic feedback (heavy/medium/success)
- **HealthKit**: zapis treningu do Health app, odczyt tętna z Watch
- **Historia**: swipe-to-delete per sesja + usuń wszystkie
- **Live HR** na ekranie timera (z Watch)
- **HR w historii**: avg i max per sesja + zbiorcze statystyki

### Wymagane działania w Xcode (jednorazowe)
- [ ] **Signing & Capabilities → Add "HealthKit"** — bez tego entitlement nie zadziała na urządzeniu
- HealthKit capability musi być włączona ręcznie w Xcode, nie da się przez pbxproj

### Otwarte TODO
- [ ] WatchKit app — dla ciągłego HR co 1s podczas treningu (zamiast co 5-10 min z tła Watch)
- [ ] Usuwanie pojedynczej sesji z edycją (np. zmiana notatki)
- [ ] Eksport danych (CSV / Share Sheet)
- [ ] Testy jednostkowe (TimerViewModel jest testowalny)

---

## Ostatnie zmiany (git)

| Commit | Opis |
|--------|------|
| (pending) | HealthKit, historia edytowalna, live HR, swipe-delete |
| `602bb01` | Must-have refactor: TimerViewModel, notifications, haptics, background |
| `3b407c9` | Initial commit GIT BOXING app |
