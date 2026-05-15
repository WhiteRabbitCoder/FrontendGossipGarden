<div align="center">
  <img src="docs/icon.png" width="140" alt="Gossip Garden logo"/>
  <h1>Gossip Garden</h1>
  <p><em>Your plants have something to say.</em></p>

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
  ![Supabase](https://img.shields.io/badge/Auth-Supabase-3ECF8E?logo=supabase&logoColor=white)
  ![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
</div>

---

Gossip Garden is a Flutter app that helps you identify, track, and connect with your plants. Point your camera at any plant, get its full care profile in seconds, and keep an eye on its health over time.

---

## What it does

**Identify plants with your camera**
Take a photo and the app identifies the species, shows you how to take care of it, and adds it to your collection — all in a few taps.

**Monitor sensor data**
Each plant can be paired with an IoT sensor. The app shows live temperature, humidity, and light readings, and tells you if your plant is happy or struggling.

**Chat with your plant**
Every species has its own personality. Open a chat and your plant will talk back — yes, really.

**Sign in your way**
Email and password, or tap your Google account directly from your phone — no browser, no redirects.

---

## Screens

| Onboarding | Identify | Profile | Chat |
|---|---|---|---|
| First-launch walkthrough that guides you through identifying your first plant | Camera viewfinder → AI identifies the species → confirm and name it | Live sensor readings + care tips for your plant | LLM-powered conversation with your plant's personality |

---

## Getting started

```bash
cd src
flutter pub get
flutter run --dart-define=BACKEND_TARGET=prod
```

That's it. The app connects to the production backend automatically.

### Build a release APK

```bash
cd src
flutter build apk --release --dart-define=BACKEND_TARGET=prod
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Built with

- **Flutter & Dart** — UI and app logic
- **Riverpod** — state management
- **google_sign_in** — native Android account picker
- **camera** — in-app viewfinder for plant photos
- **flutter_secure_storage** — keeps your session alive between restarts

---

<div align="center">
  <sub>Made with 🌱 and a lot of care</sub>
</div>
