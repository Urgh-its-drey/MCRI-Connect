# Community Water Point Monitor

A new, standalone SwiftUI iPhone app for iOS 17+. Existing Waterline and MCRI Connect projects are unchanged.

## Run on your Mac

Open `CommunityWater/CommunityWater.xcodeproj` from the repository root, select the **CommunityWater** scheme and an iPhone simulator, then press **Run**. No packages, account or signing team are needed for the simulator. For a physical iPhone, select your Apple development team under Signing & Capabilities and use a unique bundle identifier if needed.

The app opens on a welcome screen with **Create an account**, **I already have an account** and **Explore as a guest**. Guest access works immediately in **Demo** mode with clearly labelled illustrative Harare locations. These are not verified water sources. Demo reports stay on the device and are never uploaded. The sample timestamps are fixed rather than being refreshed on launch.

## Welcome and accounts

The welcome, sign-in and sign-up screens support email/password authentication through the configured community's Supabase Auth service. Open the welcome screen's gear button to configure a community. Enable the Email provider and sign-ups in Supabase Authentication. The sign-up form checks email format, an eight-character password minimum and matching confirmation. Sign-in includes password visibility and loading/error states. If email confirmation is enabled, sign-up shows inbox instructions; confirm the email in your browser, return to the app and sign in. An existing account may receive the same confirmation response to avoid exposing whether an email is registered.

Successful sign-in opens the map. Settings shows the account email and **Sign out**. Accounts are optional for browsing; the existing pilot reporting backend still permits anonymous reports and does not attach account identity to report rows. The session is local to the current app run: passwords and tokens are not saved on disk, and relaunch returns to welcome. A community change clears the current account. Offline caches and device-local reports remain available through guest access.

Real sign-in/sign-up requires a configured Supabase project and internet access. Demo mode does not create pretend accounts.

## Implemented user stories

| Story | Implementation |
|---|---|
| US01–02: find points and inspect availability | MapKit map and list with text/icon/colour status indicators |
| US03: filter by condition and source | Independent condition/type filters and name/area search |
| US04: details and freshness | Location details, observation timestamps, stale-report notice and unknown state |
| US05–06: report conditions, crowding and repairs | Form with separate condition, crowding and repair fields, optional note and observation time |
| US07: problem history | Per-point history ordered by observation time |
| US08–09: work offline | Atomic local cache, durable pending reports, foreground/reconnection retry and visible delivery states |
| US11: directions | Opens walking directions in Apple Maps |
| Extra | Saved places, My Reports, optional location access, backend settings and damaged-cache recovery |

Adding points is an administrator task in this pilot. Notifications, photos, maintenance assignments and public-launch moderation are outside this version.

## Enable live community sharing

The client and backend schema are implemented. A hosted Supabase project must be configured before real reports can be shared between devices:

1. Create a dedicated Supabase project and run `Backend/schema.sql` in its SQL editor.
2. Add verified rows to `water_points` using the dashboard. Store a stable ID, name, type (`borehole`, `tap`, `well`, `other`), area and coordinates. The SQL contains a commented example; it does not seed unverified sources.
3. Open the app's Settings and enter the project URL and **public publishable key** (or legacy public anon JWT). Secret/service-role keys are rejected.
4. Tap **Connect community**. On a second simulator or device, use the same public configuration. Submit an update and refresh the other device to see its history.

The database allows public reads and anonymous append-only reports, with row-level security and field constraints. Clients cannot change/delete points or reports. This is suitable for a supervised pilot; authenticated reporting, abuse controls and moderation are needed before a broader public launch. Report notes are public.

No backend credentials are committed. The public connection configuration is saved in local preferences. Each backend host has its own cache, separate from demo mode. Switching communities preserves reports in the original cache; reconnect to that community to resume its pending uploads.

## Offline and sync behaviour

- Reports are written to Application Support before appearing in the UI. A failed write leaves the previous state intact.
- In community mode, new reports are marked **Pending sync** and retried on reconnect, foreground entry, manual refresh and every minute while active.
- Reports use stable UUIDs. PostgREST inserts ignore duplicate IDs, so retries after an interrupted response are safe.
- The newest observation determines current condition, even if an older report uploads later. A repair event does not imply the source is working.
- Uploaded reports retain “My Reports” ownership on this device. This is device-local attribution, not an account identity.
- Cached locations, reports, saved places and history work offline. Map tiles depend on MapKit connectivity/cache; the app does not download offline map regions.
- Sync requires the app to be active; there is no guaranteed background upload. A damaged cache is preserved until explicit recovery makes a backup.
- Availability reports do not certify drinking-water quality.

## Validation

From the repository root:

```sh
xcodebuild -project CommunityWater/CommunityWater.xcodeproj \
  -scheme CommunityWater -sdk iphonesimulator -configuration Debug \
  -derivedDataPath /tmp/community-water-build CODE_SIGNING_ALLOWED=NO build

swiftc -module-cache-path /tmp/community-water-module-cache \
  CommunityWater/CommunityWater/Models.swift \
  CommunityWater/CommunityWater/CommunityAPI.swift \
  CommunityWater/CommunityWater/WaterStore.swift \
  CommunityWater/Tests/CommunityChecks.swift -o /tmp/community-water-checks
/tmp/community-water-checks

swiftc -module-cache-path /tmp/community-water-module-cache \
  CommunityWater/CommunityWater/Models.swift \
  CommunityWater/CommunityWater/AuthStore.swift \
  CommunityWater/Tests/AuthChecks.swift -o /tmp/community-water-auth-checks
/tmp/community-water-auth-checks
```

Checks cover local persistence, independent report fields, empty history, late observations, persistent upload failures, successful retry, deduplication, local ownership after refresh, isolated community/demo caches, validation, failed-save rollback and corruption recovery. The sync checks use an injected service; they do not establish that a hosted Supabase instance has been deployed.

Account checks use an injected authentication service and cover guest access, sign-out, email/password validation, missing backend configuration, confirmation-required sign-up, failed sign-in and successful account transitions. Live email delivery and authentication must also be checked against your configured Supabase project.

Manual device checks: map/list/filter combinations; marker selection; saved places; a crowded working source; repaired but still broken source; backdated reports; relaunch persistence; location allowed/denied; offline access; and two-device sync once the backend is configured.

## Git branches

`codex/community-water/mvp` integrates the project. Every authored project file has a separate `codex/community-water/file-*` branch containing its one-file commit, merged into the integration branch. These branches share the original repository commit as their base; build and run the integration branch for the complete app.
