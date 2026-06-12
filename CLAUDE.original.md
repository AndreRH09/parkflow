# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run                          # Run on connected device/emulator
flutter run -d chrome                # Run in browser
flutter run -d windows               # Run on Windows desktop
flutter build apk                    # Build Android APK
flutter build web                    # Build for web

flutter test                         # Run all tests
flutter test test/widget_test.dart   # Run single test file

flutter analyze                      # Lint (uses flutter_lints/flutter.yaml)
flutter pub get                      # Install dependencies
flutter pub add <package>            # Add dependency
flutter pub upgrade --major-versions # Upgrade all deps
```

## Architecture

**Clean Architecture**, layer-first organization.

- **SDK:** Dart ≥ 3.12.1 / Flutter stable
- **State Management:** **Riverpod** (`flutter_riverpod: ^2.6.1`) — chosen, use consistently, do NOT mix with BLoC
- **Backend:** Supabase (auth + PostgreSQL + Realtime). Client via `supabaseClientProvider`.
- **UI:** Material Design 3 (`uses-material-design: true`)
- **Platforms:** Android (primary), iOS, Web, Windows
- **App ID:** `com.example.parkflow`

```
lib/
  config/                  # AppConfig (Supabase URL, keys, Google client ID)
  data/
    repositories/          # Supabase implementations of domain interfaces
  domain/
    entities/              # Pure Dart models (no Flutter imports)
    repositories/          # Abstract interfaces
    services/              # Domain service interfaces (empty — not yet used)
    blocs/                 # Empty — NOT used; Riverpod handles state
  ui/
    pages/                 # Top-level route screens
    widgets/               # Reusable components (empty — extract here as app grows)
    theme/                 # app_theme.dart → AppColors, AppTextStyles, AppTheme
    assets/                # Images: BannerParkFlow.png, OficialLogo.jpg, PNGLogo.png
  dependency_injection/
    providers.dart         # All Riverpod providers
  main.dart                # App entry; routing driven by authStateProvider
```

**Layer rules:**
- `domain/` — zero Flutter imports; pure Dart only
- `data/` — implements `domain/repositories/` interfaces; accesses Supabase directly
- `ui/` — never imports `data/` directly; uses providers from `dependency_injection/providers.dart`
- Direct Supabase calls in UI are an **architecture violation** — route through repositories

## Routing

Navigation is **state-driven** via `authStateProvider` in `main.dart`:
```
authState = null        → LoginPage
user.needsOnboarding    → ProfileOnboardingPage
user.needsRoleSelection → RoleSelectionPage
user.role == 'host'     → HostHomePage       ✓ implemented
user.role == 'driver'   → DriverHomePage     (placeholder — real UI pending)
```
Do NOT use `Navigator.pop()` from root pages — use `pushReplacement` or invalidate `authStateProvider`.

## Theme

All styling via `lib/ui/theme/app_theme.dart`. Never hardcode colors or font sizes.

- **Colors:** `AppColors.*` (brightSnow, dustGray, graphite, mustard, accent, white, textPrimary, textSecondary, etc.)
- **Text:** `Theme.of(context).textTheme.*` or `AppTextStyles.*`
- **Font:** `'Inter'` by name — TTFs not yet embedded; falls back to system font. Do NOT re-add `google_fonts` (caused build failure: constant evaluation error).
- **Note:** Use `WidgetStatePropertyAll`, not deprecated `MaterialStatePropertyAll`.

## Current Implementation Status

### Done ✓
| File | HU | Notes |
|------|----|-------|
| `lib/ui/pages/login_page.dart` | HU-01 | Google + email/password auth, tab UI |
| `lib/ui/pages/profile_onboarding.dart` | HU-02 | Wired to Supabase via `profileRepositoryProvider`; invalidates `authStateProvider` on save |
| `lib/ui/pages/role_selection_page.dart` | HU-03 | Works; has direct Supabase call (arch violation, low priority) |
| `lib/ui/pages/host_home_page.dart` | HU-09 | Home tab: carousel of real garages w/ primary photo + "Mis Cocheras" section; Cochera tab: full list view; bottom nav |
| `lib/ui/pages/parking_config_page.dart` | HU-10 | Full form: address (GPS detect), price, dimensions, photo upload (3 slots, primary required), vehicle types, features |
| `lib/ui/pages/profile_page.dart` | — | Edit profile: fullName, phone, city (GPS detect), avatar upload → Supabase Storage; sign out |
| `lib/domain/entities/user_profile.dart` | — | Full entity with `needsOnboarding`, `needsRoleSelection`, `copyWith` |
| `lib/domain/entities/garage.dart` | — | Garage entity: id, hostId, address, dimensions, vehicleTypes, features, basePricePerHour, photoUrls (primary via getter), isActive, rating, ratingCount |
| `lib/domain/repositories/auth_repository.dart` | — | Interface: `signInWithGoogle`, `signInWithEmail`, `registerWithEmail`, `signOut` |
| `lib/domain/repositories/profile_repository.dart` | — | Interface: `saveProfile`, `updateProfile`, `uploadAvatar` |
| `lib/domain/repositories/garage_repository.dart` | — | Interface: `uploadGaragePhoto()`, `saveGarage()`, `getGaragesByHost()` |
| `lib/data/repositories/supabase_auth_repository.dart` | — | Full implementation, Google OAuth + email/password |
| `lib/data/repositories/supabase_profile_repository.dart` | — | Implements profile save/update + avatar upload to `avatars` bucket |
| `lib/data/repositories/supabase_garage_repository.dart` | — | Implements garage CRUD, photo upload to `garage-photos` bucket, fetches garages by host |
| `lib/dependency_injection/providers.dart` | — | `supabaseClientProvider`, `authRepositoryProvider`, `profileRepositoryProvider`, `garageRepositoryProvider`, `authStateProvider`, `myGaragesProvider` |
| `lib/ui/widgets/app_bottom_nav.dart` | — | Shared bottom nav used by HostHomePage |
| `lib/ui/theme/app_theme.dart` | — | Centralized design tokens |
| `android/app/src/main/AndroidManifest.xml` | — | INTERNET permission added |

### Pending (next steps)
| HU | What | Key files to create/modify |
|----|------|---------------------------|
| HU-11 | AvailabilityPage (schedule, master switch) | `ui/pages/availability_page.dart` |
| HU-12 | RequestsPage (incoming bids, accept/reject) | `ui/pages/requests_page.dart`, `domain/entities/bid.dart` |
| HU-13 | EarningsPage (bar chart with fl_chart) | `ui/pages/earnings_page.dart` |
| EPIC 2 | DriverHomePage + search/map/bid form | `ui/pages/driver_home_page.dart`, `domain/entities/search_filter.dart` |

### Not started
- EPIC 2 (Driver): map, search, bid form, reservation timer (HU-05 to HU-08)
- EPIC 4 (Feedback): bidirectional rating system (HU-14)

## Known Issues / Debt

- `role_selection_page.dart`: calls Supabase directly (bypasses repository layer — fix when refactoring).
- Inter font not embedded — add TTFs to `assets/fonts/` if custom typography is required.
- `domain/blocs/` and `domain/services/` directories are empty and unused; ignore them.
- `profile_page.dart` + `parking_config_page.dart`: use `image_picker` + `geolocator` + `geocoding` — ensure Android/iOS permissions in manifests.

## Dependencies (current)

```yaml
supabase_flutter: ^2.8.4
google_sign_in: ^6.2.2
flutter_riverpod: ^2.6.1
image_picker: ^1.1.2     # avatar upload in ProfilePage
geolocator: ^14.0.2      # GPS city detection in ProfilePage
geocoding: ^4.0.0        # reverse geocode in ProfilePage
```

Planned additions (not yet added):
```yaml
fl_chart: ^0.70.0        # HU-13 earnings bar chart
```

## UI / Widget Organization

**Page Pattern:** each `pages/*.dart` is a full screen. Private widgets use `_` prefix (e.g. `_GarageCard`, `_StatusPill`). Extract reusable components to `widgets/` only after 2+ uses.

**HostHomePage Structure:**
- Home tab: header + search + filter chips + map placeholder + garage carousel (`_buildGarageCarousel()`, uses `myGaragesProvider`)
- Cochera tab: full garage list (`_buildGarageTab()`) w/ empty state + FAB to add
- Uses `_GarageCard` (compact carousel), `_GarageListTile` (full row), `_GaragePhoto` (lazy load network image)

**Riverpod Pattern:**
- Async data (Future) → `FutureProvider` (use `.when(loading/error/data)`)
- Async stream (Stream) → `StreamProvider` (use `.value` for latest or `.when()`)
- Invalidation: `ref.invalidate(provider)` after mutations (e.g., save garage → invalidate `myGaragesProvider`)
- Watchers: `ref.watch()` triggers rebuild; `ref.read()` one-time access (no rebuild)

**Supabase + Repository Pattern:**
1. UI calls `ref.read(garageRepositoryProvider).method()`
2. Repository implements domain interface, talks to Supabase
3. Convert DB rows to entity via `.fromMap()` factory
4. UI never touches Supabase or Firestore directly

## Tests

`test/` directory. `flutter_test` is the only test dep. Widget tests use `WidgetTester`; unit tests use `test()`.
