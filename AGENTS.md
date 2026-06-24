# AGENTS.md - Frontend Guide

This document is designed to provide context and guidance for any AI agent or developer interacting with the `frontendGossipGarden` repository. It provides an analysis of the structure, the general context of its functions, and rules for extending, refactoring, or migrating code.

## 1. Architectural Structure

The frontend is a **Flutter** application utilizing **Riverpod** for state management and following a feature-based folder structure. 

### Directory Breakdown
- **`lib/main.dart`**: The root of the application, configuring the `ProviderScope` and wrapping the UI in a global NavigationState layout (a custom routing strategy utilizing `IndexedStack` rather than `Navigator.push`).
- **`lib/core/`**: Shared infrastructure and utilities.
  - `config/`: Compile-time configurations (e.g., `AppConfig`).
  - `services/`: Low-level services such as JWT storage (`TokenStorage`) and base authentication logic against the backend (`backend_auth_service.dart`).
  - `observers/`: E.g., `SessionObserver`, which monitors globally for `UnauthorizedException` and triggers sign-outs.
- **`lib/features/`**: The core application modules organized by feature (`auth`, `plants`, etc.). Each feature contains:
  - `data/`: Models, Enums, and Datasources (HTTP Clients).
  - `presentation/`: Riverpod Providers, Screens, and custom Widgets.

## 2. General Context of Key Functions

- **Auth Lifecycle (`features/auth/presentation/providers/auth_provider.dart`)**:
  Manages the session state. Bypasses Firebase Auth in favor of direct Supabase token generation via `backend_auth_service`. Uses `flutter_secure_storage` for token persistence. Exposes `backendTokenProvider` which is reactively watched by all API datasources.
- **Plant Data Loading (`plant_api_datasource.dart` & Providers)**:
  `plantsProvider` polls for plant updates and relies on backend-side joins (common and scientific names are fetched dynamically). `plantRealtimeSensorProvider` streams sensor data dynamically.
- **Plant Identification Flow (`features/plants/presentation/screens/plant_identify_screen.dart`)**:
  Handles local camera usage, image processing (orientation, compression to 1024x1024), and coordinates the multi-step UI flow: uploading -> processing -> selecting candidates -> confirming -> creating.
- **Chat Experience**:
  State is managed by `chatMessagesProvider`. Reads directly from the `/chat` endpoints. Does not cache locally in Firestore; completely defers to the backend's memory logic.
- **Navigation (`MainScreen` and Overlays)**:
  Uses an `IndexedStack` and overlay widgets for navigation to preserve state locally without complex routing stacks. Back behavior is manually handled via `notifier.handleBack()`.

## 3. Preparation for Migrations, Refactoring, and New Features

When refactoring or adding functionalities, strictly adhere to these rules:

1. **State Management**: Use **Riverpod**. Wrap API calls in `FutureProvider` or `StateNotifierProvider`. Watch `backendTokenProvider` in all datasources to handle token refreshes automatically.
2. **Feature Isolation**: Place new features in `lib/features/<new_feature>/`. Do not bleed domain models into the global space unless strictly necessary.
3. **No Repositories Layer**: Continue the existing pattern of connecting UI Providers directly to Datasources. Avoid adding a repository abstraction layer unless logic complexity severely demands it.
4. **Auth Flow**: Do NOT integrate Firebase Auth. All auth is handled via Supabase keys and the custom backend API. If a datasource gets a 401, it must throw an `UnauthorizedException` so the `SessionObserver` can gracefully handle it.
5. **No Code Generation**: Models are hand-written. Avoid introducing `build_runner` or `freezed` unless globally agreed upon. 
6. **UI Conventions**: Keep screens lightweight and split logic into smaller widgets. Ensure user-facing text remains in Spanish. Use `NetworkImage` for plant photos via `photo_url` provided by the API.
