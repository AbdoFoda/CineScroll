# CineScroll 🎬

A native iOS app for discovering what's playing in cinemas right now. Built with SwiftUI, powered by [TMDB](https://www.themoviedb.org/), and designed with offline-first resilience in mind.

> **iOS 18+ · Swift 5.10 · Xcode 16 · Zero third-party app dependencies**

<br>

| Now Playing | Movie Detail |
|:-----------:|:------------:|
| ![Now Playing screen](https://github.com/user-attachments/assets/d972d860-020e-4ceb-ab14-4271e6f095f1) | ![Movie Detail screen](https://github.com/user-attachments/assets/7b8d6845-0166-4e36-bb46-0f4d2d3946ec) |

<br>

## What is this?

CineScroll is a movie discovery app I built to explore modern SwiftUI patterns in a realistic, production-like setting — not a tutorial app, not a toy. It has real pagination, real offline handling, real tests, and a real security story (your TMDB API key never leaves the server).

If you're learning iOS development, this might be a useful reference for:

- MVVM with `@Observable` and strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`)
- Async/await networking with retry, exponential backoff, and rate-limit awareness
- Offline-first UX with URLCache fallback and connectivity toasts
- Snapshot testing with deterministic placeholders (light + dark)
- Keeping API secrets off the device via a Cloudflare Worker proxy

---

## Getting started

You'll need **Xcode 16+** and **Node.js 18+** for the proxy worker.

### 1. Clone and open

```bash
git clone https://github.com/your-username/CineScroll.git
cd CineScroll
open CineScroll.xcodeproj
```

### 2. Set up the TMDB proxy

The app never sends your TMDB API key directly — requests go through a lightweight Cloudflare Worker that injects the key server-side. To run it locally:

```bash
cd worker
npm install
cp .dev.vars.example .dev.vars   # then open .dev.vars and paste your TMDB key
npm run dev                      # starts at http://127.0.0.1:8787
```

You'll need a free TMDB API key from [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api).

For deploying to production, see [`worker/README.md`](worker/README.md).

### 3. Point the app at your worker

The worker URL is set in `Config/Secrets.xcconfig`. The committed default points at the production worker — for local development, copy the example and override it:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Edit CINESCROLL_API_BASE_URL to http://127.0.0.1:8787
```

### 4. Build and run

Hit **⌘R** in Xcode. That's it — the iOS Simulator will launch with live TMDB data.

> **Note:** SwiftUI Previews use `PreviewMovieRepository` (static fixture data) and don't need the worker running at all.

---

## Project structure

```
CineScroll/
├── App/            App entry point, RootView, dependency wiring
├── Core/           Models, networking, repository, deep links
│   ├── Models/     Movie, MovieDetail, PagedResponse
│   ├── Network/    HTTPClient, RetryPolicy, APIEndpoint, TMDBConfig
│   ├── Repository/ MovieRepository protocol + implementation
│   └── Storage/    Recent search persistence (UserDefaults-backed)
├── DesignSystem/   Spacing, corner radii, grid, and size tokens
├── Features/       One folder per screen
│   ├── MovieList/  Now Playing grid + view model
│   ├── MovieDetail/Full detail screen + view model
│   └── Search/     Search + autocomplete + view model
├── Shared/         Reusable components, modifiers, accessibility helpers
├── Preview/        Preview catalog and fixture repository
└── Testing/        UITest and snapshot runtime configuration
```

---

## Architecture

MVVM with a repository layer. Views are kept deliberately thin — all business logic lives in `@MainActor`-isolated view models that talk to a `MovieRepository` protocol. Swapping the real implementation for a mock (in tests or previews) requires zero changes to any view.

```
┌──────────────┐    async/await    ┌──────────────────────┐
│  SwiftUI     │ ───────────────► │  @MainActor ViewModel │
│  Views       │                  │  (list/detail/search) │
└──────┬───────┘                  └───────────┬───────────┘
       │                                      │
       │  Environment (AppDependencies)        │ calls
       ▼                                      ▼
┌─────────────────────────────────────────────────────────┐
│  MovieRepository (protocol)                              │
│    └── MovieRepositoryImpl → HTTPClient (protocol)       │
└─────────────────────────────────────────────────────────┘
```

I went with MVVM + repository rather than TCA/Redux because the scope doesn't call for a global store. Fewer moving parts, easier to follow the data flow, and `@Observable` fits naturally without pulling in a DSL.

### A few notable details

| Topic | Decision |
|-------|----------|
| **API key security** | The TMDB key lives only on the Cloudflare Worker. The iOS app reads a proxy base URL from `Info.plist` — the key itself never touches the device. |
| **Concurrency** | `SWIFT_STRICT_CONCURRENCY = complete`. Global `MainActor` isolation was deliberately *not* set project-wide so that `Codable` models stay usable from nonisolated repository code. |
| **Retry logic** | Exponential backoff with jitter, 3 attempts by default. `NetworkError.rateLimited` respects the server's `Retry-After` header. Offline errors skip retries entirely and fall through to the URLCache. |
| **Search debounce** | `Task.sleep` + cooperative cancellation — no Combine. The delay is injectable so tests can run instantly without artificial waits. |
| **Offline UX** | Three-tier image fallback (in-process `NSCache` → `URLSession` network → stale `URLCache`). API responses also fall back to stale URLCache when offline. Connectivity changes surface as non-blocking bottom toasts. |
| **Deep links** | `cineScroll://movie/{id}` — wired up in `RootView` via `onOpenURL`. |

---

## Running the tests

```bash
# Build once, then run unit tests
xcodebuild -scheme CineScroll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build-for-testing

xcodebuild -scheme CineScroll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test-without-building -only-testing:CineScrollTests
```

### Snapshot tests

Snapshot tests use [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) with deterministic grey placeholders instead of real images, so golden files are stable across machines and CI runs. Reference PNGs live in `CineScrollTests/Snapshots/__Snapshots__/` and cover both light and dark appearances.

**22 cases across:** individual components, full feature screens in all states (loading, error, empty, populated), and navigation shells.

```bash
# Verify existing snapshots
xcodebuild -scheme CineScroll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test-without-building \
  -only-testing:CineScrollTests/ComponentSnapshotsTests \
  -only-testing:CineScrollTests/FeatureSnapshotsTests \
  -only-testing:CineScrollTests/SearchSnapshotsTests \
  -only-testing:CineScrollTests/ScreenSnapshotsTests

# Re-record golden images after an intentional UI change
SNAPSHOT_RECORD=1 xcodebuild -scheme CineScroll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test \
  -only-testing:CineScrollTests/ComponentSnapshotsTests \
  -only-testing:CineScrollTests/FeatureSnapshotsTests \
  -only-testing:CineScrollTests/SearchSnapshotsTests \
  -only-testing:CineScrollTests/ScreenSnapshotsTests
```

### UI tests

UI tests launch the app with `-ui-testing`, which swaps in `PreviewMovieRepository` (no network, instant search) and disables animations for reliable automation.

```bash
xcodebuild -scheme CineScroll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:CineScrollUITests
```

---

## Contributing

Contributions are welcome — whether it's a bug fix, a docs improvement, or a new feature idea. A few ground rules:

- **Open an issue first** for anything bigger than a typo or small bug fix, so we can align before you put in the work.
- **Keep PRs focused.** One logical change per PR makes review much faster.
- **Tests are required** for changes to networking, view model logic, or storage. Snapshot tests should be re-recorded if you intentionally change UI.
- **No new app-target dependencies.** The zero-dependency constraint is intentional — if you think a library is genuinely necessary, make the case in an issue first.

If you're unsure whether something is in scope, just open an issue and ask.

---

## License

MIT — see [`LICENSE`](LICENSE) for the full text.

---

*This product uses the TMDB API but is not endorsed or certified by TMDB.*
