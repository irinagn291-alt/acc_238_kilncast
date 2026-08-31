# Kilncast

Rank who will go cold. Restoke the falling brick.

Kilncast is for people who keep meaning to write and then do not. Home is a hexagonal kiln wall. Every brick is a person colored by predicted heat seven days from now, not by the last hello. Tap a falling brick, pick a channel, and write a Touch. Heat recomputes. Never-touched stay at zero on a separate ash rail so they cannot hide inside the forecast.

No account, no ads, no Game tab. The kiln is the mechanic.

## Architecture

Reactive cell graph. Each `KilnPerson` is a node whose heat is a derived `HeatCell`, never a stored field. The only write that mutates the graph is inserting an `EmberTouch`. Cadence and forecast-horizon edits change inputs; every cell recomputes. A `ForecastCell` evaluates the same logistic at now + horizon and is the kiln-wall sort key. Band cells (ash, falling, hot) are derived partitions. The SwiftUI host owns chrome; a `UICollectionView` representable owns the hex layout and brick registration.

This fits a contact-decay wall: heat is a function of idle time and cadence, so storing T would lie after the clock moves. A tab plus a last-contact list would be a clone.

## Imminent-freeze forecast rank

This is why someone would pick the kiln. Bricks order by predicted T seven days from now, not current T and not last-contact age. A person at 80 who will hit 20 this week sits above a person already at 15 who is stable. Restoke writes a Touch; `lastTouchAt` jumps to now and the brick climbs the logistic curve. Never-touched stay at 0 on the ash rail.

Invariant, unit-tested:

`days = idle/86400`; `decay = cadence×0.58`; `T = 100/(1+(days/decay)^2.35)`, clamp 0…100. Never-touched = 0. Not a countdown.

## Design

Firebrick kiln: soot, ember, fireclay. Palette lives in `Assets.xcassets` and is reached only through `FireclayPalette`: background `#140E0C`, surface `#2B1A14`, ink `#F4E6D4`, accent `#E24A1B`, muted `#A08978`. Type is Futura for every step of a six-step scale (display, title, headline, body, caption, micro). Hard edges. Spacing unit 8 pt. Tap targets 44 pt. Navigation is kiln-first; Restoke and Settings are sheets.

## Art

Style: raku firing still life.

Base prompt reused for every asset:

```
Raku firing still life, cracked glaze pot, soot kiln interior, ember glow, fireclay walls, dark ground, no text, no letters, no logo, tactile ceramic surface, studio lighting, painterly glaze drips
```

| Image set | Prompt |
| --- | --- |
| `kln_AppIcon` | Raku firing still life, single raku tea bowl with an ember crack, soot kiln ground, fireclay body, centred, filling the canvas, no text, no letters, no rounded corners, no drop shadow, subject inside the middle 80 percent, opaque |
| `kln_Splash` | Raku firing still life, vertical kiln interior, quiet uncluttered centre band, soot walls, distant raku vessels, ember glow at the edges, no text |
| `kln_Onboarding1` | Raku firing still life, unfired bricks waiting on a fireclay shelf inside a dark kiln, one glance at the product, no text |
| `kln_Onboarding2` | Raku firing still life, a hand restoking a falling hex brick with an ember, mid-gesture, soot and fireclay, no text |
| `kln_Onboarding3` | Raku firing still life, a kiln wall of glowing raku bricks after many touches, accumulated heat, no text |
| `kln_EmptyHome` | Raku firing still life, cold kiln, grey ash on the floor, one unlit fireclay brick, calm and inviting, never sad, no text |
| `kln_EmptyList` | Raku firing still life, empty fireclay shelf, no bricks, soot ground, calm, no text |
| `kln_CardBackdrop` | Raku firing still life, low-contrast abstract raku glaze, soot and fireclay, quiet enough for text, no letters |
| `kln_ControlFace` | Raku firing still life, hexagonal firebrick face, ember edge, soot centre, single physical control, no text |
| `kln_TwistHero` | Raku firing still life, one falling brick about to go dark, frost-bloom on raku glaze, 7-day freeze emblem, no text |
| `kln_SuccessMark` | Raku firing still life, small ember spark on a raku shard, confirmation mark, no text |
| `kln_HeaderDecor` | Raku firing still life, wide kiln-arch ornament, soot, ember, fireclay, decorative band, no text |

## How this is not a repeat

First `contact_decay` in the portfolio. Home is a hex kiln ranked by 7-day predicted heat, not a last-contact countdown list. Distinct from Washfolio (year canvas), Clickface (group), Restante (payday lock), Occupath (Marey desk), and any food-tracker skin. No slots, OFF, kcal, or Game tab.

## Build

```bash
cd Kilncast
xcodegen generate
xcodebuild -scheme Kilncast -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.kilncast.wall`. Contact: https://kilncast.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `kln.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
