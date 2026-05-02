# GIT BOXING — TODO
*Ostatnia aktualizacja: 2026-05-02*

---

## 🔴 KRYTYCZNE / Duży wpływ na UX

### [ ] WatchKit app — ciągły pomiar tętna
**Dlaczego:** Bez oddzielnej aplikacji na Watch tętno jest mierzone co ~5-10 min (tryb tła). Watch app z `HKWorkoutSession` mierzy co 1 sekundę i streamuje do iPhone.
**Co zrobić:**
- Dodaj nowy target: `File → New Target → watchOS → Watch App`
- `WatchSessionManager.swift` (watchOS): `HKWorkoutSession` + `HKLiveWorkoutBuilder`
- `WatchConnectivityManager.swift` (iOS): odbieranie danych przez `WatchConnectivity.framework`
- Synchronizuj stan (runda/przerwa) z zegarkiem — Watch wyświetla aktualną fazę
- Wysyłaj HR co sekundę do iPhone przez `WCSession.transferUserInfo()`
**Pliki do stworzenia:** `WatchApp/`, `GIT_BOXING/WatchConnectivityManager.swift`

---

### [ ] Live Activity + Dynamic Island
**Dlaczego:** Użytkownik może śledzić rundę na ekranie blokady i w Dynamic Island bez otwierania apki.
**Co zrobić:**
- Dodaj target `Widget Extension`
- `BoxingTimerAttributes: ActivityAttributes` (czas, runda, faza, tętno)
- `Activity<BoxingTimerAttributes>` start w `TimerViewModel.onAppear()`
- Update co sekundę przez `activity.update()`
- Zakończ przez `activity.end()` w `saveSession()`
**Wymaga:** `NSSupportsLiveActivities = YES` w Info.plist (pbxproj)

---

## 🟡 WAŻNE / Jakość i kompletność

### [ ] Tryb głośności / Ciche dźwięki gdy iPhone na wyciszeniu
**Dlaczego:** Boxer z rękawicami nie przestawi manualnie trybu. Dźwięki powinny grać nawet na silent.
**Co zrobić:**
- `AVAudioSession.setCategory(.playback)` jest już ustawione ✅
- Dodaj `INFOPLIST_KEY_UIRequiresPersistentWiFi` = NO
- Sprawdź czy `AVAudioSession` jest aktywna przed każdym dźwiękiem
- **Status:** Prawdopodobnie już działa, wymaga testu na urządzeniu

---

### [ ] Usuwanie / Edycja pojedynczej sesji
**Dlaczego:** Swipe-to-delete jest, ale brakuje długiego wciśnięcia → edycja notatki, zmiana daty, ręczne dodanie sesji.
**Co zrobić:**
- `SessionDetailView.swift`: pełny ekran z detalami sesji
- Długie wciśnięcie na `SessionRow` → sheet z edycją
- Pole `notes: String?` w `TrainingSession` (+ migracja Codable z defaultem `""`)
- Ręczne dodawanie sesji (przydatne gdy ktoś trenował bez telefonu)

---

### [ ] Eksport danych
**Dlaczego:** Użytkownik chce zabrać dane do Excel, trenerowi, do analizy.
**Co zrobić:**
- `ShareSheet` z CSV (`date,rounds,roundTime,breakTime,completedRounds,activeTime,avgHR,maxHR`)
- `ExportManager.swift` generuje plik CSV/JSON
- Przycisk eksportu w `HistoryView` obok kosza
- Opcjonalnie: eksport do PDF z wykresem tętna

---

### [ ] Wykresy w historii
**Dlaczego:** Wizualizacja postępów — tętno w czasie, liczba treningów per tydzień.
**Co zrobić:**
- Import `Charts` (SwiftUI Charts, iOS 16+, już dostępne)
- `ProgressChartView.swift`: wykres słupkowy — treningi per tydzień
- `HeartRateChartView.swift`: linia avg HR z kolejnych sesji
- Zakładka lub sekcja w `HistoryView`

---

### [ ] Preset plany treningowe
**Dlaczego:** Nowy użytkownik nie wie ile rund/czasu wybrać. Gotowe plany = niższy próg wejścia.
**Co zrobić:**
- `TrainingPreset.swift`: struct z nazwą, ikoną, rundami, czasami
- Presety: "Beginner 3×2min", "Intermediate 6×3min", "Advanced 10×3min", "HIIT 8×1min", "Sparring 12×3min"
- `PresetPickerView.swift`: poziomy scroll przed `TimerSetupView`
- Zapis ostatnio użytego presetu w `UserDefaults`

---

### [ ] Powiadomienia push — przypomnienie o treningu
**Dlaczego:** Retencja użytkownika. "Nie trenowałeś od 3 dni — czas na rękawice 🥊"
**Co zrobić:**
- `ReminderManager.swift` — harmonogram `UNUserNotificationContent` cyklicznych
- Ustawienia w `ContentView` lub osobny `SettingsView`: dni tygodnia + godzina
- Sprawdzaj ostatni trening przy każdym uruchomieniu, planuj powiadomienia
**Uprawnienia:** `UNUserNotificationCenter` (już mamy `requestPermission()`) ✅

---

## 🟢 NICE TO HAVE / Polishing

### [ ] Onboarding (pierwsze uruchomienie)
- Ekran powitalny wyjaśniający jak używać apki
- Prośba o HealthKit + Notifications z kontekstem ("po co to komu")
- `@AppStorage("hasSeenOnboarding")` flaga

---

### [ ] Motywy kolorystyczne
- Obecny: czerwono-czarny (Fire)
- Dodatkowe: niebieski (Ice), zielony (Jungle), fioletowy (Night)
- `ThemeManager.swift` z `@Published var theme: Theme`
- Podmiana `Color(hex: "FF4500")` na `Theme.accent`

---

### [ ] Dźwięki własne / wybór dźwięku
- Pozwól wybrać inny gong/dzwonek z zestawu dźwięków
- Ewentualnie: tapnij → podgląd dźwięku
- `SoundSettingsView.swift`

---

### [ ] Krajobraz (Landscape) podczas treningu
- Obróć telefon poziomo → duży timer na pełnym ekranie
- Przydatne gdy telefon leży na worku
- `GeometryReader` w `TimerView` + warunkowy layout

---

### [ ] Siri Shortcut
- "Hej Siri, zacznij trening bokserski"
- `AppIntents` framework (iOS 16+)
- `StartTrainingIntent: AppIntent` z parametrami rund/czasu

---

### [ ] iCloud sync historii
- `NSUbiquitousKeyValueStore` lub `CloudKit` zamiast `UserDefaults`
- Synchronizacja historii między iPhone a iPad
- `TrainingStore` wymaga lekkiego refaktoru żeby wspierać CloudKit

---

### [ ] Testy jednostkowe
**Dlaczego:** `TimerViewModel` ma czystą logikę `recoverFromElapsed` którą łatwo przetestować.
**Co zrobić:**
- `GIT_BOXINGTests/TimerViewModelTests.swift`
- Test: 300s w tle → poprawna faza
- Test: trening ukończony w tle → `isFinished = true`
- Test: `recoverFromElapsed(0)` → brak zmiany stanu
- Folder testów już istnieje (`GIT_BOXINGTests`)

---

### [ ] Accessibility
- `accessibilityLabel` i `accessibilityValue` na timerze
- Wsparcie dla Dynamic Type
- VoiceOver: ogłaszaj fazę przy zmianie (`UIAccessibility.post(notification:)`)

---

## 📋 Szybkie poprawki (< 1 dzień każda)

| | Zadanie | Plik |
|-|---------|------|
| [ ] | Wibracje gdy app w tle (przez Watch) | `WatchSessionManager` |
| [ ] | Animacja przy swipe-delete w historii | `HistoryView.swift` |
| [ ] | Podgląd tętna na ekranie setup (ostatnie z Watch) | `ContentView.swift` |
| [ ] | "Streak" — ile dni z rzędu trenowałeś | `TrainingStore.swift` |
| [ ] | Zabezpieczenie przed podwójnym tapnięciem START | `TimerSetupView` |
| [ ] | Licznik kalorii (szacunek z czasu treningu) | `HealthKitManager.swift` |
| [ ] | Pokaż czas od ostatniego treningu na ekranie głównym | `ContentView.swift` |
