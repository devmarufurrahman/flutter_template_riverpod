---
# 🚀 Flutter Ultimate Riverpod Starter
### *Empowering Developers with Feature-First Clean Architecture & Instant Boilerplate*

Developed and maintained by **[devmarufurrahman](https://github.com/devmarufurrahman)**.
---

## 💻 System Prerequisites

Before running the automation script, ensure your machine has the following installed:

1.  **Flutter SDK:** (Version 3.10.4 or higher recommended)
2.  **Dart SDK:** (Included with Flutter)
3.  **Git:** (For version control)
4.  **IDE:** VS Code or Android Studio with Flutter/Dart plugins.
5.  **RPS Package:** Active globally by running:
    `dart pub global activate rps`

---

## 🛠️ How to Use & Run

### 1. Project Generation

Run the main automation script from your terminal:

```bash
dart flutter_temp.dart
```

_Input your project name (e.g., `my_awesome_app`) when prompted._

### 2. Mandatory: Add Roboto Font 🔠

The generated architecture uses **Roboto** as the default font. You **MUST** add it before running the app to avoid UI issues.

1.  **Download:** Download the Roboto font family from [Google Fonts](https://fonts.google.com/specimen/Roboto).
2.  **Place Files:** Create a folder `assets/fonts/` (if not already there) and paste the `.ttf` files.
3.  **Update Pubspec:** Ensure your `pubspec.yaml` contains:
    ```yaml
    flutter:
      fonts:
        - family: Roboto
          fonts:
            - asset: assets/fonts/Roboto-Regular.ttf
            - asset: assets/fonts/Roboto-Bold.ttf
              weight: 700
    ```

### 3. Post-Setup Commands (Step-by-Step)

After generating the project and adding fonts, run these commands in order:

```bash
# 1. Navigate to your project
cd your_project_name

# 2. Install all dependencies
flutter pub get

# 3. Generate Localization (L10n)
flutter gen-l10n

# 4. Generate Assets & Boilerplate code
dart run rps gen

# 5. Finally, Run the App
flutter run
```

> **Tip:** For continuous code generation while developing (Riverpod & Freezed), run:
> ```bash
> dart run rps watch
> ```

---

## 🏗️ Folder Architecture

A **Feature-First Clean Architecture** powered by **Riverpod 2.x/3.x** and **GoRouter**:

```text
lib/
├── app.dart                # Main App Widget (ConsumerWidget, ScreenUtil, GoRouter, ConnectivityBanner, Dynamic Theme & Locale)
├── main.dart               # Entry point (ProviderScope with async overrides)
├── core/
│   ├── router/             # GoRouter Provider (routerProvider) & AppRoutes
│   ├── localization/       # LocaleNotifier, localeProvider, and BuildContext.tr extension
│   ├── network/            # DioProvider, DioHelper & HttpMethod with Retry & Auth interceptors
│   ├── services/           # StorageService, NetworkService, Location, Media, Notifications
│   ├── theme/              # Light/Dark AppTheme, ThemeModeNotifier, themeModeProvider
│   ├── common/             # Global Widgets, Styles, Dialogs, ConnectivityBanner & Custom BottomSheet
│   └── utils/
│       ├── constants/      # App Colors, Paths, API Endpoints, Centralized Imports
│       ├── device/         # Device & Platform specific utilities
│       ├── formatters/     # Date, Currency, and Phone formatters
│       ├── helpers/        # Snackbars, Dialogs, and UI helpers
│       ├── logging/        # Structured Console Logging (AppLoggerHelper)
│       ├── navigation/     # Context-safe AppNavigation & Global Keys
│       └── validators/     # Form Validation logic
├── features/               # Feature modules (Feature-First Architecture)
│   └── [feature_name]/
│       ├── views/          # Screen UI (ConsumerWidget)
│       ├── controllers/    # State Notifiers & Providers (AutoDisposeNotifier)
│       ├── repositories/   # Data Source & API Repositories (Provider)
│       ├── models/         # Feature Data Models
│       └── widgets/        # Feature-specific sub-widgets (Modularized)
└── l10n/                   # Multi-language (ARB files)
```

---

## ⚡ Feature Automation

In your project root, you will find `create_feature.dart`. Use it to generate a complete Riverpod module instantly.

**Command:**

```bash
dart create_feature.dart <feature_name>
```

_Example:_ `dart create_feature.dart login`

**Automation Highlights:**

- Creates all sub-folders (`views`, `controllers`, `repositories`, `models`, `widgets`).
- Generates clean boilerplate code with modern Riverpod `AutoDisposeNotifier`, `Provider`, and modularized UI widgets.
- **Auto-Exports:** Automatically registers all module exports in `lib/core/utils/constants/imports.dart`.
- **Auto-Route:** Updates `lib/core/router/app_routes.dart` and injects `GoRoute` into `lib/core/router/app_router.dart`.

---

## 📦 Key Packages Included

- **State Management & Codegen:** `flutter_riverpod`, `riverpod_annotation`, `freezed_annotation`, `json_annotation`
- **Routing:** `go_router`
- **Networking:** `dio`, `dio_smart_retry`, `dio_cache_interceptor`, `pretty_dio_logger`
- **Storage:** `shared_preferences`
- **UI/UX:** `flutter_screenutil`, `lottie`, `flutter_svg`, `google_fonts`, `shimmer`, `zo_animated_border`
- **Services:** `firebase_core`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics`, `geolocator`
- **Dev & Automation:** `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `rps`, `flutter_dotenv`

---

## 🚦 Usage Guidelines

- **State Reading & Mutation:**
  - In UI: Use `ref.watch(controllerProvider)` to reactively listen to state.
  - In Event Callbacks: Use `ref.read(controllerProvider.notifier)` to call methods.
- **Dynamic Localization:**
  - Change language from anywhere:
    ```dart
    ref.read(localeProvider.notifier).changeLanguage('bn');
    ```
  - Translate strings: `context.tr.appName` or `AppLocalizations.of(context)!.appName`
- **Dynamic Theme Mode:**
  - Toggle Theme from anywhere:
    ```dart
    ref.read(themeModeProvider.notifier).toggleTheme();
    ```
- **Automatic Non-blocking Network Banner:**
  - Whenever internet drops, a sleek red banner (`ConnectivityBanner`) slides down automatically from the top of the screen and slides back up once reconnected.
- **Resilient Network Client:**
  - Dio is preconfigured with `RetryInterceptor` (auto retries 3 times on transient dropouts) and automatic Bearer Token attachment.
- **Context-Safe Navigation & Alerts:**
  - Navigation: `context.go(AppRoutes.login)` or `AppNavigation.go(AppRoutes.login)`
  - SnackBars: `AppHelperFunctions.showSnackBar('Operation successful');` (works with or without context)
- **Centralized Imports:**
  - For most screens, only one import is needed:
    ```dart
    import 'package:your_project/core/utils/constants/imports.dart';
    ```

---

## 📜 Copyright & License

Designed and Automated by **devmarufurrahman**.

> _"Code is poetry, automation is the rhythm."_

© 2026 | **devmarufurrahman** | All Rights Reserved.
