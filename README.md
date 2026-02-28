# ErgoGuard HK AI 🛡️
### Personal Ergonomic Guardian for Hong Kong Workers
**For the 2nd OSH Innovation & Technology Award (中學組)**

---

## What It Does

ErgoGuard HK AI is a fully offline Android app that uses your phone's **front camera** and **gyroscope** to:

- Detect body posture in real-time using ML Kit Pose Detection (Google)
- Calculate **REBA scores** every 2–3 seconds (construction sector)
- Detect tasks automatically (rebar tying, wok stirring, heavy lifting, etc.)
- Alert in **Cantonese/English** via voice + haptic vibration
- Forecast fatigue and recommend micro-breaks
- Show OSHC-aligned safety micro-learning cards
- Export PDF shift reports

No cloud. No subscription. No extra hardware. Just your phone.

---

## Quick Start (Build & Run)

### Requirements
- Flutter SDK 3.x ([install](https://flutter.dev/docs/get-started/install))
- Android Studio + Android SDK (API 24+)
- A physical Android phone (camera + gyroscope required)

### Steps

```bash
# 1. Clone / download this folder
cd ergoguard_hk

# 2. Get dependencies
flutter pub get

# 3. Connect your Android phone via USB (enable Developer Mode + USB Debugging)
flutter devices

# 4. Run on your device
flutter run

# 5. For release APK:
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## Project Structure

```
ergoguard_hk/
├── lib/
│   ├── main.dart                    # App entry + routing
│   ├── models/
│   │   └── posture_model.dart       # PostureData, ShiftSession, enums
│   ├── services/
│   │   ├── pose_service.dart        # ML Kit + angle calculation engine
│   │   ├── reba_service.dart        # REBA/RULA scoring + task detection
│   │   └── alert_service.dart       # TTS (Cantonese) + haptics + tips
│   ├── screens/
│   │   ├── home_screen.dart         # Sector selection + start
│   │   ├── monitor_screen.dart      # Live camera + real-time analysis
│   │   ├── report_screen.dart       # Charts + PDF export
│   │   └── settings_screen.dart     # Language, sensitivity, privacy
│   └── widgets/
│       ├── risk_gauge.dart          # Circular REBA score dial
│       ├── angle_bars.dart          # Joint angle indicator bars
│       └── micro_learning_card.dart # OSHC safety tip overlay
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # Camera + sensor permissions
├── pubspec.yaml                     # Dependencies
└── README.md
```

---

## Hardware Used
| Sensor | Purpose |
|--------|---------|
| Front Camera | Full-body pose landmark detection via ML Kit |
| Gyroscope | Motion magnitude for repetitive task detection & dynamic scoring |

**Phone mounting suggestions:**
- Construction: Helmet mount (facing worker's body at ~1.5m distance from a fixed point) OR chest-level stand
- Catering: Counter stand or adjustable arm clamp

---

## Key Technical Details

### Pose Detection
- Uses **Google ML Kit Pose Detection** (Accurate model) — on-device, no internet
- Extracts 33 body landmarks per frame
- Computes angles: neck, trunk, both shoulders, both elbows, both knees

### REBA Scoring (Labour Dept / OSHC Aligned)
| Score | Risk | Action |
|-------|------|--------|
| 1–3 | Low 低 | Monitor |
| 4–7 | Medium 中 | Investigate |
| 8–10 | High 高 | Immediate action |
| 11–15 | Very High 極高 | Stop & correct |

### Task Auto-Detection
The app classifies 8 task types from pose+gyro patterns without any manual selection.

### Fatigue Index
Cumulative weighted exposure model:
- High-risk seconds × 2 + Medium-risk seconds × 1
- Normalised over shift duration
- Predicts optimal break timing

---

## Validation Plan (for competition submission)
1. **Technical accuracy**: 70 controlled poses vs. goniometer (target: <7° mean error)
2. **Pilot**: 75 participants (45 construction, 30 catering tasks simulated)
3. **Instruments**: Nordic Musculoskeletal Questionnaire, VAS, System Usability Scale
4. **Target**: ≥50% reduction in high-risk posture duration (4-week period)
5. **Statistics**: Paired t-tests, p<0.01

---

## OSH References
- Labour Department — Guidance Notes on Manual Handling Operations
- Labour Department — Guidance Notes on Standing at Work
- OSHC — Construction & Catering Sector Resources
- Occupational Safety and Health Statistics Bulletin Issue No. 25 (August 2025)
- McAtamney & Corlett (1993) — REBA Method
- Nordic Musculoskeletal Questionnaire (Kuorinka et al., 1987)

---

## Privacy Statement
- **All processing is 100% on-device** — no video, images, or personal data leave the phone
- Anonymous aggregate statistics sharing is **opt-in only** and off by default
- No accounts, no login, no cloud required

---

*Developed for the 2nd OSH Innovation & Technology Award (中學組) | ErgoGuard HK Team 2026*
