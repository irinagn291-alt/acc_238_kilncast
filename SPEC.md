# Kilncast — Build Specification

> Portfolio app 50, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Rank who will go cold. Restoke the falling brick.

| Field | Value |
| --- | --- |
| Product name | Kilncast |
| Bundle identifier | `com.kilncast.wall` |
| Domain | https://kilncast.pro |
| Contact URL | https://kilncast.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `kln_` |
| User-Agent | `Kilncast/1.0 (iOS; +https://kilncast.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Kilncast -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

Heat is a forecast.

### 2.1 User flow

1. Open the kiln: every person is a brick colored by predicted heat seven days from now
2. Add a person and a cadence — how often they should be touched
3. Tap a falling brick to restoke: pick a channel and write a Touch
4. Heat recomputes from lastTouchAt; the brick climbs; never-touched stay on the ash rail at zero
5. Open Settings to edit cadence, forecast horizon, or an optional reminder

### 2.2 Essential behaviour

- Logistic heat T = 100/(1+(days/decay)^2.35), decay = cadence×0.58, never-touched = 0
- Home ranked by predicted T in 7 days, not current T
- Restoke writes a Touch; a tap without a log does not heat
- Ash rail for never-touched so they cannot hide in the forecast
- Local only; no required social-graph import

---

## 3. Uniqueness assignment for Kilncast

| Axis | Assigned value |
| --- | --- |
| Architecture | **Reactive cell graph (each Person is a derived heat cell; Touch is the only write)** |
| UI approach | **SwiftUI + UICollectionView hexagonal UICollectionViewLayout representable** |
| Naming convention | **Ember lexicon** |
| File organization | **By decay band (ash, falling, hot)** |
| Dependency strategy | **None (zero external dependencies)** |
| Design direction | **Firebrick kiln (soot, ember, fireclay)** |
| Typography | **Futura** |
| Navigation pattern | **Kiln-first; restoke in place; Settings as a sheet** |
| AI art style | **Raku firing still life** |
| Functional twist | **Imminent-freeze forecast rank (7-day predicted heat)** |
| Persistence | **SwiftData (Person and Touch only; heat is always derived)** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — contact_decay

**Core** — Heat is a forecast.

**Audience** — People who keep meaning to write and then do not. They need a wall that shows who will go cold, not a list of last-contact dates.

**User flow**

1. Open the kiln: every person is a brick colored by predicted heat seven days from now
2. Add a person and a cadence — how often they should be touched
3. Tap a falling brick to restoke: pick a channel and write a Touch
4. Heat recomputes from lastTouchAt; the brick climbs; never-touched stay on the ash rail at zero
5. Open Settings to edit cadence, forecast horizon, or an optional reminder

**Essential features**

- Logistic heat T = 100/(1+(days/decay)^2.35), decay = cadence×0.58, never-touched = 0
- Home ranked by predicted T in 7 days, not current T
- Restoke writes a Touch; a tap without a log does not heat
- Ash rail for never-touched so they cannot hide in the forecast
- Local only; no required social-graph import

**Twist** — Imminent-freeze kiln. The wall ranks people by predicted heat seven days from now, not by how cold they are today. A person at 80 who will hit 20 this week outranks a person already at 15 who is stable. Restoke writes a Touch and the brick climbs the logistic curve. Never-touched stay at 0 on a separate ash rail so they cannot hide inside the forecast. Cadence still sets decay; the home verb is catch the falling brick, not tap the coldest name.

**Why this is not a repeat** — First contact_decay in the portfolio. The kiln is the product: bricks ranked by 7-day predicted heat, restoke writes a Touch, never-touched sit on an ash rail. That is not a last-contact list, not Washfolio's year canvas, not Clickface's group, not Restante's payday lock, and not a food-tracker skin. No slots, OFF, kcal, or food barcode. Unique axes are new catalog values because those menus are empty; screens, daykey, and search_api take leftover catalog entries.

### 3.0a Craft from the shipped portfolio

These rules come from apps that already shipped. Follow them. Do not copy their type names or layouts.

**Ship these. They are what made the real apps feel finished.**

- Home **is** the mechanic (canvas, rings, tower, wheel, matrix, dial, board, console). A tab plus a list of records is a clone.
- One persisted verb on home. Unit-test that verb. A decorative Game / Aura / Circuit / Nest / Sweep tab is filler — do not ship one.
- Every primary list has an empty state: generated art, one headline, one line, one CTA. Blank `List` fails.
- Simulator seed only, once, behind a versioned key. Never seed on a device.
- Contact URL on Settings (or Goals). App Review looks for it.
- Offline: if the product needs a catalog, a local shelf must catch empty/fail search. A spinner forever fails.
- Denied camera (when used) explains the state and routes to Settings. Silent no-op fails.
- Numbers go through `NumberFormatter`. Day edges use `Calendar.current.startOfDay`.
- One haptic on a successful commit, none on navigation.
- VoiceOver labels on every icon-only control. Colour is never the only signal.

**Review screenshots (21AUG App02–09)**

The running app, not `ImageRenderer`. One launch argument, three keys:

- `-ReviewScreen today` — home after onboarding (often a no-op)
- `-ReviewScreen log` — log / statement / planner
- `-ReviewScreen goals` — goals / targets / profile

Read `ProcessInfo.processInfo.arguments` **once**, **after** onboarding is done.
If onboarding is still showing, the hook never fires.

Companion (Simulator only):

- Seed one demo day behind a versioned key (`{prefix}.demo.v1`).
- Mark onboarding complete in the same seed so the hook is reachable.
- `#if targetEnvironment(simulator)`. Never seed on a device.
- Seed fills the primary surface (four slot posts from the local shelf).

Driver (outside the app): build → install on iPhone and iPad → launch with the
argument → wait until the UI settles → `xcrun simctl io <udid> screenshot`.
Name files `{App}-{today|log|goals}.png`. Pick any available simulator UDID.

**Family `contact_decay`**
- Home: Hex kiln wall. Coldest cells first.
- Invariant (unit-test this): days = idle/86400; decay = cadence×0.58; T = 100/(1+(days/decay)^2.35), clamp 0…100. Never-touched = 0. Not a countdown.
- Empty: The hive is cold. Add a person and restoke.
- Fake that fails: A last-contact countdown list.
- Never: Logistic heat is the product.

### 3.1 Architecture contract

The app is a reactive cell graph: every Person is a node whose heat is a derived cell, never a stored field. The only write that mutates the graph is inserting a Touch; cadence and forecast-horizon edits change inputs and every cell recomputes. A HeatCell reads lastTouchAt from the latest Touch (or nil), cadenceDays, and now, then applies days = idle/86400, decay = cadence×0.58, T = 100/(1+(days/decay)^2.35), clamp 0…100, never-touched = 0. A ForecastCell evaluates the same formula at now+7 days and is the kiln wall sort key. Band cells (ash, falling, hot) are derived partitions: ash is lastTouchAt == nil; falling and hot split on forecast T. UICollectionView bricks bind to these cells and do not own mutable heat.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Home is a SwiftUI-hosted UICollectionView with a custom hexagonal UICollectionViewLayout; each person is a brick cell, not a List row. The representable owns the collection view, hex layout, and cell registration; SwiftUI owns chrome, empty state, Restoke composer, and Settings. Brick fill tracks forecast T, and a second non-colour signal (ember glyph, crack, or ash hatch) travels with it so colour is never the only cue. Empty kiln uses EmptyHome art, headline "The hive is cold.", one supporting line, and one CTA to add a person and restoke. Do not ship a tab bar or a last-contact countdown list.

### 3.3 Naming contract

Convention: Ember lexicon.

Examples to follow: `KilnWall`, `BrickHeat`, `AshRail`, `RestokeDraft`

### 3.4 Dependency contract

Zero external packages. No SPM remotes, no CocoaPods, no vendored third-party UI. Hex layout, heat math, and the SwiftData stack are first-party source in this target. VisionKit is a leftover catalog axis and is not imported; the app does not use the camera. The leftover search_api is unused; there is no remote catalog.

### 3.5 Navigation contract

Kiln-first: after onboarding the hex wall is the only root. Tapping a brick opens Restoke in place as a sheet over that brick; there is no pushed contact-detail stack. Settings is a sheet from a kiln toolbar control and holds default cadence, forecast horizon, optional reminder, contact URL https://kilncast.pro/contact-us, re-run onboarding, and resetAllData(). ReviewScreen today is the kiln after onboarding; log is the Restoke composer; goals is the Settings sheet. Read ProcessInfo.processInfo.arguments once, only after onboarding is done.

### 3.6 Screen composition contract

Single screen entire app. Physical screens: Kiln, Restoke, Settings. The kiln wall is the whole product: hex bricks ranked by 7-day predicted heat plus a separate ash rail for never-touched people. Family labels Hive and Coldest are the same wall, not two tabs. Restoke is an in-place composer (channel plus Touch text) over the tapped brick; a tap without a log does not heat. Settings is a sheet. Onboarding is a cover that writes defaults and a completion flag; skip still writes sensible defaults. No Today, Scan, Search, or Goals screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By decay band (ash, falling, hot)**

```
Kilncast/
  Ash/
  AshRailView.swift
Falling/
  FallingBandView.swift
  ForecastRank.swift
Hot/
  HotBandView.swift
EmberGraph/
  EmberGraph.swift
  HeatCell.swift
  HeatFormula.swift
Kiln/
  KilnWallRepresentable.swift
  HexKilnLayout.swift
  BrickCell.swift
  RestokeComposer.swift
  SettingsSheet.swift
Fireclay/
  FireclayPalette.swift
  FuturaScale.swift
Store/
  Person.swift
  Touch.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Hive
A first-class screen for **Hive**. Must render empty, populated and error states.

### 5.3 Coldest
A first-class screen for **Coldest**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Person** — named per this app's convention.
- **Touch** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Firebrick kiln (soot, ember, fireclay)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#140E0C` | Screen background |
| `surface` | `#2B1A14` | Cards, rows, sheets |
| `ink` | `#F4E6D4` | Primary text and icons |
| `accent` | `#E24A1B` | Primary action, key figure, progress fill |
| `muted` | `#A08978` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Futura**

Futura Medium for kiln titles and brick names, Futura Book for body and Restoke copy, Futura Medium for the forecast T figure. At most six steps behind one accessor: display, title, headline, body, caption, micro. Tabular figures for T through NumberFormatter. Dynamic Type; at the largest size a brick still shows name and T. No second type family.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **SwiftData (Person and Touch only; heat is always derived)**

SwiftData stores only Person and Touch. Person holds id, display name, cadence in days, createdAt. Touch holds id, person inverse, channel, body, touchedAt. Heat, forecast T, band, and lastTouchAt are always derived; do not persist them. One ModelContainer, VersionedSchema v1, and a SchemaMigrationPlan from the start; cascade-delete Touches with Person. Map models to Sendable structs at the repository seam; the UI never sees @Model. Optional reminder weeks use ISO week date (YYYY-Www) for the leftover daykey axis; heat math uses Calendar.current.startOfDay and idle seconds, not the week string. resetAllData() clears both models and is reachable from Settings. Simulator seed only, once, behind kln.demo.v1, and the same seed marks onboarding complete.

This app uses **SwiftData**. SwiftData has several sharp edges that produce
runtime crashes and silent data loss; all of the following are mandatory.

**Container**

- Exactly one `ModelContainer`, created once at app start and injected. Never
  construct a container inside a view body or a computed property.
- Declare an explicit `Schema` listing every `@Model` type.
- Define a `VersionedSchema` and a `SchemaMigrationPlan` from version 1, even
  though there is nothing to migrate yet. Retrofitting migration later is the
  single most expensive SwiftData mistake.
- Handle container creation failure with a recoverable path, not `try!`.

**Modelling**

- Every relationship must declare its inverse with `@Relationship(inverse:)`.
  A missing inverse is the most common SwiftData bug: it produces duplicated
  objects and orphaned rows that only appear after a relaunch.
- Every to-many relationship must declare a delete rule, normally
  `@Relationship(deleteRule: .cascade)` for owned children.
- Use `@Attribute(.unique)` on the product barcode. Understand that this makes
  inserts behave as upserts.
- Do not store derived values (day totals, remaining budget). Compute them.
- Store the day as a normalised `startOfDay` value if you query by day, and
  index it. Querying by a raw timestamp will silently miss rows.

**Threading**

- `ModelContext` is not `Sendable`. Never capture one in a `Task` that hops
  actors.
- Background work uses `@ModelActor`. Inside it, fetch by `PersistentIdentifier`
  rather than passing model objects across the boundary.
- Models themselves are not `Sendable`. Map to plain structs before handing data
  to the UI layer or across an actor boundary.

**Queries**

- `@Query` belongs in views only, with an explicit and stable `sort:`.
- `#Predicate` supports a restricted subset of Swift. Keep predicates to simple
  comparisons on stored properties; do the rest in memory. Calling an arbitrary
  Swift function inside a predicate compiles but traps at runtime.
- Do not build a predicate that captures a non-`Sendable` value.

**Saving**

- Call `context.save()` explicitly after a batch of mutations rather than
  relying on autosave, so the moment of persistence is deterministic.
- Delete through the context, then save, then let the UI update from the query.

**Testing**

- Tests use `ModelConfiguration(isStoredInMemoryOnly: true)`.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Kilncast/1.0 (iOS; +https://kilncast.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.social-networking`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.social-networking
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Imminent-freeze forecast rank (7-day predicted heat)

Imminent-freeze forecast rank is the home sort: bricks order by predicted T seven days from now, not by current T and not by last-contact age. A person at 80 who will hit 20 this week sits above a person already at 15 who is stable. Restoke writes a Touch; lastTouchAt jumps to now and the brick climbs the logistic curve on the next graph tick. Never-touched people stay at 0 on the ash rail so they cannot hide inside a forecast that would otherwise invent a number from missing history. Unit-test the heat formula and the forecast sort separately; a last-contact countdown list fails the family.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Raku firing still life**

Base prompt, reused and extended for every asset:

```
Raku firing still life, cracked glaze pot, soot kiln interior, ember glow, fireclay walls, dark ground, no text, no letters, no logo, tactile ceramic surface, studio lighting, painterly glaze drips
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `kln_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `kln_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `kln_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `kln_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `kln_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `kln_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `kln_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `kln_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `kln_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `kln_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `kln_TwistHero` | 1024x1024 | allowed | Hero art for the 'Imminent-freeze forecast rank (7-day predicted heat)' feature screen. |
| 11 | `kln_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `kln_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`kln_AppIcon`** — 1024x1024

```
Raku firing still life, single raku tea bowl with an ember crack, soot kiln ground, fireclay body, centred, filling the canvas, no text, no letters, no rounded corners, no drop shadow, subject inside the middle 80 percent, opaque
```

**`kln_Splash`** — 1290x2796

```
Raku firing still life, vertical kiln interior, quiet uncluttered centre band, soot walls, distant raku vessels, ember glow at the edges, no text
```

**`kln_Onboarding1`** — 1024x1536

```
Raku firing still life, unfired bricks waiting on a fireclay shelf inside a dark kiln, one glance at the product, no text
```

**`kln_Onboarding2`** — 1024x1536

```
Raku firing still life, a hand restoking a falling hex brick with an ember, mid-gesture, soot and fireclay, no text
```

**`kln_Onboarding3`** — 1024x1536

```
Raku firing still life, a kiln wall of glowing raku bricks after many touches, accumulated heat, no text
```

**`kln_EmptyHome`** — 1024x1024

```
Raku firing still life, cold kiln, grey ash on the floor, one unlit fireclay brick, calm and inviting, never sad, no text
```

**`kln_EmptyList`** — 1024x1024

```
Raku firing still life, empty fireclay shelf, no bricks, soot ground, calm, no text
```

**`kln_CardBackdrop`** — 1200x800

```
Raku firing still life, low-contrast abstract raku glaze, soot and fireclay, quiet enough for text, no letters
```

**`kln_ControlFace`** — 512x512

```
Raku firing still life, hexagonal firebrick face, ember edge, soot centre, single physical control, no text
```

**`kln_TwistHero`** — 1024x1024

```
Raku firing still life, one falling brick about to go dark, frost-bloom on raku glaze, 7-day freeze emblem, no text
```

**`kln_SuccessMark`** — 512x512

```
Raku firing still life, small ember spark on a raku shard, confirmation mark, no text
```

**`kln_HeaderDecor`** — 1200x600

```
Raku firing still life, wide kiln-arch ornament, soot, ember, fireclay, decorative band, no text
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `kln.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `KilncastTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Kilncast -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Reactive cell graph (each Person is a derived heat cell; Touch is the only write)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI + UICollectionView hexagonal UICollectionViewLayout representable**.
- [ ] Navigation matches **Kiln-first; restoke in place; Settings as a sheet**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Futura** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Kilncast
xcodegen generate
xcodebuild -scheme Kilncast -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Kilncast -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
