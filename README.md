# CineScroll

Movie discovery for iOS (17+) powered by [The Movie Database (TMDB)](https://www.themoviedb.org/) API. Swift **5.10** (Xcode 16 toolchain), SwiftUI + MVVM + repository, async/await networking, and XCTest coverage.

_Add a simulator screenshot at `docs/screenshot.png` and link it here if you want a visual in the README._

## Setup

1. Open `CineScroll.xcodeproj` in Xcode 16+.
2. API base URL is in `Config/Secrets.xcconfig` (committed). For a machine-specific URL, copy `Secrets.xcconfig.example` and optionally add `Config/Secrets.xcconfig` to `.gitignore` (see comment in `.gitignore`).
3. Start the TMDB proxy (keeps the API key off the device):
   ```bash
   cd worker
   npm install
   cp .dev.vars.example .dev.vars   # set TMDB_API_KEY for local dev
   npm run dev                      # http://127.0.0.1:8787
   ```
   See [worker/README.md](worker/README.md) for deploy and production secrets.
4. Build & run on the iOS 17+ simulator or device.

The app never sends `api_key` to TMDB. Previews use `PreviewMovieRepository` and do not need the Worker.

**Deep links:** `cineScroll://movie/{id}` (see `Support/CineScroll-Info.plist`; plist lives outside the synchronized `CineScroll/` folder to avoid duplicate `Info.plist` copy rules).

## Project layout

```
CineScroll/
├── App/           Entry, RootView, dependencies, environment
├── Core/          Models, network, repository, deep links
├── DesignSystem/  Spacing, radii, sizes, grid tokens
├── Features/      List, detail, search screens + view models
├── Preview/       Preview catalog, preview repository, snapshot shells
├── Shared/        Reusable UI, accessibility helpers
└── Testing/       UITest + snapshot runtime flags (still in app target)
```

## Architecture

MVVM keeps SwiftUI views thin; a repository abstracts TMDB so view models stay testable with mocks. This is intentionally smaller than TCA/Redux: fewer moving parts, straightforward data flow, and native `Observation`/`@Observable` fit the app’s scope without introducing a global store or DSL.

```
┌──────────────┐    async/await    ┌─────────────────────┐
│   SwiftUI    │ ───────────────► │  @MainActor VM       │
│   Views      │                  │  (list/detail/search)│
└──────┬───────┘                  └──────────┬──────────┘
       │                                   │
       │ Environment (`AppDependencies`)   │ calls
       ▼                                   ▼
┌──────────────────────────────────────────────────────┐
│ `MovieRepository` (protocol)                          │
│   └── `MovieRepositoryImpl` → `HTTPClient` (protocol)│
└──────────────────────────────────────────────────────┘
```

## Assumptions (documented)

| Topic | Decision |
|--------|----------|
| **API key** | TMDB key lives only on the **Cloudflare Worker** (`worker/`, Wrangler secret / `.dev.vars`). iOS reads `CINESCROLL_API_BASE_URL` from Info.plist via `Secrets.xcconfig`. Missing URL → `NetworkError.missingAPIKey`. |
| **Transport** | App → Worker (HTTPS in prod) → TMDB. Posters still load from `image.tmdb.org` (public CDN). MITM on the device no longer exposes your TMDB key in query strings. |
| **MVVM vs TCA** | MVVM + repository for clarity, testability, and low ceremony; no global reducer graph. |
| **iOS versions** | Deployment **iOS 17**. Navigation zoom uses `.navigationTransition(.zoom)` on `NavigationLink` when **iOS 18+**; earlier releases use standard push. |
| **Third-party** | App: none. Tests: [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) (SPM, unit-test target only). |
| **Concurrency** | `SWIFT_STRICT_CONCURRENCY = complete`. Project-wide `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` was **removed** so `Codable` models stay usable from nonisolated repository code; view models remain `@MainActor`. |
| **Debounced search** | `Task.sleep` + cancellation (no Combine for networking); delay is injectable for tests. |

## Tests

```bash
xcodebuild -scheme CineScroll -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing
xcodebuild -scheme CineScroll -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test-without-building -only-testing:CineScrollTests
```

Fixtures live under `CineScrollTests/Fixtures/`.

### Snapshot tests

Uses [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) with deterministic image placeholders (`SNAPSHOT_TESTING=1` via `SnapshotTestCase`). Reference PNGs live under `CineScrollTests/Snapshots/__Snapshots__/` (light + dark per case).

**Coverage (22 cases):** components (`MovieCard`, placeholder, suggestion row, error states, loading-more), features (detail content/loading/error, grids, loading placeholders, now playing screen), search (empty, loading, no results, results, recents), screens (detail + search shells with navigation).

```bash
# Verify snapshots
xcodebuild -scheme CineScroll -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test-without-building \
  -only-testing:CineScrollTests/ComponentSnapshotsTests \
  -only-testing:CineScrollTests/FeatureSnapshotsTests \
  -only-testing:CineScrollTests/SearchSnapshotsTests \
  -only-testing:CineScrollTests/ScreenSnapshotsTests

# Record / refresh golden images after intentional UI changes
SNAPSHOT_RECORD=1 xcodebuild -scheme CineScroll -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test \
  -only-testing:CineScrollTests/ComponentSnapshotsTests \
  -only-testing:CineScrollTests/FeatureSnapshotsTests \
  -only-testing:CineScrollTests/SearchSnapshotsTests \
  -only-testing:CineScrollTests/ScreenSnapshotsTests
```

### UI tests

Launch with `-ui-testing` (preview repository, no network). Run `CineScrollUITests` from Xcode or:

```bash
xcodebuild -scheme CineScroll -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:CineScrollUITests
```
