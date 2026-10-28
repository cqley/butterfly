# MOTION_SPEC — measured from the reference recording

Source: `26-10-28_02-21-35.mp4` (working dir, Oct 28 02:21 — the newest of the two
videos on disk; the other, `~/downloads/recording.mkv`, is older and was not used).

## What the recording actually is

A 1920x1080 / 60 fps / 9.02 s (541 frames) screen capture of a **YouTube video
playing in a browser** — "A full walkthrough of my Dynamic Island Quickshell" by
saneAspect. The island being measured is *that* shell, inside the player viewport,
not a direct capture.

Consequences, all of which bound the accuracy below:

- The player's video area measures **x 208..1713 (1506 px), y 124..971 (848 px)**
  (aspect 1.776 = 16:9), measured off `f0001` by scanning for the teal/page-bg
  transition. Everything is therefore at **scale 0.7848** relative to the source.
- Source pixels = recording pixels x **1.2742**, **assuming the author recorded a
  1920x1080 screen**. This is the single biggest unverifiable assumption. Two
  independent checks corroborate it (see "Confidence"), but it is not proven.
- Two lossy encodes (author's capture -> YouTube -> this re-capture) plus YouTube's
  ambient-glow page tint. Edges are soft; integer-px readings carry about +/-1 px.
- Effective frame cadence jitters: measured sizes occasionally repeat for 2 frames,
  so any single duration is good to roughly +/-1-2 frames (+/-17-33 ms).

All "rec" values below are recording pixels (directly measured); all "src" values
are rec x 1.2742.

## Method

- All 541 frames extracted with ffmpeg (`-vsync 0`), no resampling.
- Per-frame island bounding box (`measured.txt`, 541 rows, zero failures):
  pass 1 takes a column darkness profile over rows 133..170 and walks the
  contiguous dark run containing x=961; pass 2 takes a row darkness profile over
  the inset x-band from pass 1. Union-over-rows in pass 1 is what makes it immune
  to the white glyphs that break naive contiguous-run scans.
- Easing fitted by least squares over candidate Qt curves with the end frame free
  (`fit.pl`), then re-fitted on **pooled, normalised** data across all six
  transitions (`pool.pl`) to average out the cadence jitter.
- Layout measured from per-column / per-row max-luminance profiles on settled
  frames (`maxcol.pl`, `maxrow.pl`); corner radii from per-row edge walks
  (`edge.pl`).
- Scripts and `measured.txt` are in the session scratchpad, not the repo.

## Segment map

The island is centred at x≈961 in every state (player centre = 960.5).

| segment | frames | time | state |
|---|---|---|---|
| idle | 1–71 | 0–1183 ms | W=69 H=27 |
| hover pop in | 71–82 | 1183–1350 | W 69→82 |
| hover hold | 82–95 | 1350–1583 | W=82 H=31 |
| hover pop out | 95–105 | 1583–1733 | W 82→69 |
| idle / hover x2 | 105–186 | 1733–3083 | repeats the pop twice more |
| **click 1**: hover→week | 186–198 | 3083–3283 | W 84→201, H 33→92 |
| week hold | 198–251 | 3283–4167 | W=201 H=92 |
| **leave**: week→idle | 252–262 | 4183–4350 | collapses *straight to idle* |
| hover + **click 1** again | 282–306 | 4683–5083 | W 82→201 |
| **click 2**: week→calendar | 323–336 | 5383–5583 | W 201→265, H 93→222 |
| calendar hold | 336–375 | 5583–6233 | W=265 H=222 |
| **click 3**: calendar→week | 375–387 | 6233–6433 | steps back one level |
| week hold | 387–422 | 6433–7017 | |
| **leave**: week→idle | 422–434 | 7033–7217 | |
| (unrelated) control centre | 466–526 | 7750–8750 | separate popup, see below |

The flow in the video is exactly the one specified: hover pops, click 1 opens the
week strip, click 2 opens the calendar, click 3 steps back to the week strip,
mouse-leave collapses. **Click at max depth steps back one level, it does not
close** — matching the behaviour already encoded in `IslandPop.qml`.

Frames 466–526 show a large quick-settings panel (Wi-Fi / Bluetooth / Focus /
Game Mode / Sound / Display / Notifications). It is **not** the island expanding:
the idle pill and app icon stay visible at x 888..997 while the panel occupies
x 1010..1417. It is a separate control-centre popup anchored to the right-hand
status icon. Out of scope for Part B; noted for the idea list.

## Geometry per state

Measured on `f0001` (idle), `f0085` (hover), `f0220` (week), `f0350` (calendar).
Top gap is measured from the player's video-area top edge (y=124).

| state | W rec | W src | H rec | H src | top gap rec | top gap src | radius rec | radius src |
|---|---|---|---|---|---|---|---|---|
| idle | 69 | 88 | 27 | 34 | 9 | 11.5 | 13.5 (= H/2) | 17 |
| hover | 82 | 104 | 31 | 40 | 15 | 19 | 15.5 (= H/2) | 20 |
| week | 201 | 256 | 92 | 117 | 15 | 19 | ~18 | ~23 |
| calendar | 265 | 338 | 222 | 283 | 14 | 18 | ~16 | ~20 |

- **idle and hover are true pills** (radius = height/2); verified against a circular
  corner model on `edge.pl` output (predicted inset 8.4 px at depth 1 for r=13.5,
  measured 8).
- **week and calendar are rounded rects, clearly not pills** (week r≈18 against a
  half-height of 46). The 18 vs 16 difference between them is inside measurement
  noise — treat as **one radius, ~22 src px**.
- The hover state **moves down as well as growing**: top edge +6 rec (+7.6 src),
  bottom edge +10 rec (+12.7 src), i.e. the centre drops ~8 rec (~10 src) while
  height grows only 4 rec. Once popped, the top edge stays at 138–139 for every
  expanded state — only idle sits higher.
- Idle is three separate chips (app icon x 888..912, clock pill x 927..995, wifi
  x 1010..1030). On hover the clock pill grows and the two side chips **push
  outward** ~9 rec each. On expand the side chips are simply **occluded** by the
  growing panel — they do not animate away.

## Timing and easing

**Every transition is ~200 ms, ease-out, with no overshoot anywhere.** Width and
height never exceed their settled value by more than 1 px (within noise) in any of
the six transitions.

| transition | start→end frame | duration | best single-segment fit |
|---|---|---|---|
| idle→hover | 71→82..84 | 183–217 ms | OutQuad (rms 0.79 px on W) |
| hover→idle | 95→105..108 | 167–217 ms | OutQuad (rms 0.79 px) |
| hover→week (A) | 186→198 | 200 ms | OutQuart (rms 1.27 px on H) |
| hover→week (B) | 293→306 | 217 ms | linear/InOutQuad (rms 3.22) |
| week→calendar | 323→336 | 217 ms | linear (rms 7.38) |
| calendar→week | 375→387 | 200 ms | linear (rms 5.69) |
| week→idle | 422→434 | 200 ms | OutQuad (rms 2.30) |

Single-segment fits disagree because of the cadence jitter. Pooling all segments on
a normalised progress-vs-time axis resolves it cleanly:

| curve | expand RMS | collapse RMS |
|---|---|---|
| **OutQuad** | **0.067** | **0.058** |
| OutCubic | 0.110 | 0.147 |
| OutQuart | 0.167 | 0.207 |
| linear | 0.219 | 0.139 |
| InOutQuad | 0.228 | 0.149 |
| OutExpo | 0.236 | 0.281 |

**`Easing.OutQuad` at ~200 ms, both directions, every transition.** The pooled data
sits very slightly below pure OutQuad over the first ~15 % of the curve, so a
marginally better fit is `cubic-bezier(0.33, 0.0, 0.2, 1.0)` — but the improvement
is within noise and OutQuad is the honest answer.

This **contradicts the current guessed values** in `Theme.qml`: `islandEnterEase`
`OutBack` + `islandEnterOvershoot` 1.3, `islandExitEase` `OutQuart`, and the
100/120/90 ms durations. The reference has no overshoot, no enter/exit asymmetry,
and one uniform duration.

## Content staging

**There is no stagger and no delayed fade.** On `f0187` — the *first* frame of the
week expansion, container still at 120 of its final 201 px — the week strip is
already fully drawn at full opacity. Content grows with the container (it is
scaled/clipped by it), it does not fade in after it.

The clock is the one thing that resizes: cap height 9 rec (11.5 src) at idle **and**
at hover, 13 rec (16.6 src) in the week state — it grows ~1.44x only when the week
strip opens, not on hover.

## Week strip layout (`f0220`)

Panel 201x92 rec (256x117 src), content centred at x=960.5.

- **5 bright cells**, centres at x = 917, 938, 960, 983, 1004.
  **Pitch 21.75 rec = 27.7 src** — within 7 % of butterfly's existing `cellW: 30`.
- Edge fade by peak luminance: centre 182, ±1 → 104 / 74, ±2 → 54 / 57, beyond ±2
  nothing detectable. So roughly **±1 near-full, ±2 about half, ±3 ≈ 0** — the same
  shape as the existing classic `Week.qml` fade, not a flat 5-cell capsule.
- **Today** (centre): accent number, visibly larger than its neighbours, and the
  weekday label is the **full abbreviation ("SAT")** while every other cell shows a
  single initial ("T", "F", "S", "M").
- A very subtle rounded highlight sits behind today's cell: **#0B0907**, ~4 % white
  over the black panel.
- Sunday renders red, matching the existing `weekend` rule.
- Vertical layout, offsets from panel top (rec → src):

  | element | top | bottom | height |
  |---|---|---|---|
  | clock cap | 23 → 29 | 35 → 45 | 13 → 17 |
  | weekday labels | 47 → 60 | 56 → 71 | 9 → 12 |
  | date numbers | 63 → 80 | 73 → 93 | 11 → 14 |
  | panel bottom | — | 91 → 116 | — |

## Calendar layout (`f0350`)

Panel 265x222 rec (338x283 src).

- **7 columns**, centres x = 857.5, 892, 926, 960, 994.5, 1029.5, 1064.
  **Pitch 34.4 rec = 43.8 src.**
- **6 date rows**, centres y = 209, 234, 259, 284, 309, 334.
  **Pitch 24.9 rec = 31.7 src.**
- **Sunday-first** header: S M T W T F S, dim (~50 % white).
- Side padding 12.3 rec = 15.7 src; bottom padding ~12.5 rec = 16 src.
- Header row (title centre y=161.5, i.e. 23.5 rec / 30 src below panel top): bold
  centred "September 2026" flanked by **circular ghost nav buttons** (`←` `→`),
  fill #0A0C09 (~4 % white), diameter ~17.7 rec = 22.6 src.
- Weekday header centre y=185 (47 rec / 60 src below panel top).
- **Today**: filled accent circle, diameter 21 rec = **26.8 src**, with dark text
  inside (not accent text on a tinted pill — a solid accent disc).
- Out-of-month dates dimmed to roughly 25–30 %.

Note this calendar is substantially **larger than butterfly's current one**: column
pitch 43.8 src vs `cellW: 30`, row pitch 31.7 src vs `cellH: 24`.

## Shadow

A soft drop shadow is present and is offset downward.

- To the side (`f0220`, y=190): background green channel falls 131 → 100 at the
  panel edge (~24 % darkening) over ~40 rec (~50 src).
- Below (`f0220`, x=960): 128 → 72 at the edge (~44 % darkening) over ~30 rec
  (~38 src).

**Low confidence.** YouTube's ambient-mode page glow tints the area around the
player, and two lossy encodes sit on top. Treat as "soft shadow, downward offset,
roughly 40 src px blur" and tune by eye.

## Colours (reference only — butterfly derives these from the wallpaper)

| role | value |
|---|---|
| accent | `#4CDFB0` |
| panel background | `#000000` (fully opaque) |
| weekday header | ~50 % white |
| today highlight (week strip) | `#0B0907` |
| nav button fill (calendar) | `#0A0C09` |

## Proposed `Theme.qml` properties

Replacing the current guessed `// island` block. Values in butterfly's own units
(src px, rounded to the shell's existing scale where they nearly coincide).

```
// island
islandMode            "classic"          mode toggle; classic stays default
islandPopDuration     200                was 100 — measured ~200
islandStepDuration    200                was 120 — measured ~200
islandCollapseDuration 200               was 90  — measured ~200
islandEase            Easing.OutQuad     replaces islandEnterEase/islandExitEase
                                         (no asymmetry, no overshoot in the video)
islandPopW            +16                idle→hover width delta (src 104-88)
islandPopH            +5                 idle→hover height delta (src 40-34)
islandPopOffsetY      +8                 hover drops DOWN (current token is -3, wrong sign)
islandWeekW           252                = 9 * cellW - 18; measured 256
islandWeekH           117
islandWeekRadius      22                 NOT a pill (current token is pill-shaped)
islandWeekCells       9                  measured 9 slots w/ edge fade (current token is 5)
islandWeekClockScale  1.44               clock grows only at week depth
islandCalW            338
islandCalH            283
islandCalRadius       22                 same radius as week (current token is 20)
islandCalCellW        44                 vs current cellW 30
islandCalCellH        32                 vs current cellH 24
islandCalPad          16
islandTodayDia        27                 solid accent disc
islandTodayTint       0.04               week-strip today highlight
islandShadowBlur      40                 low confidence
islandShadowY         8                  low confidence
```

Tokens to **delete**: `islandEnterEase`, `islandEnterOvershoot`, `islandExitEase`,
`islandPopScale`, `islandWeekPillW`, `islandWeekPillH`.

## Confidence

**High** — segment map; the ~200 ms uniform duration; ease-out with no overshoot;
no content stagger; all settled-state W/H/radius; week cell pitch; calendar grid
pitch and row/column counts; Sunday-first; today treatments; click-at-max-depth
steps back one level; mouse-leave collapses straight to idle.

**Medium** — the exact curve (OutQuad is the best pooled fit, but OutCubic is not
excluded); per-transition durations to better than +/-20 ms; font sizes, which are
derived from cap heights rather than measured directly.

**Low / not measured** —

- **The 1920x1080 source assumption.** Corroborated twice: measured week cell pitch
  27.7 src vs butterfly's `cellW: 30` (7 % off), and measured week panel width
  252 src vs butterfly's `openW: 252` (exact). Both are consistent with a 1080p
  source, neither proves it. If the author recorded at 1440p, every src value here
  is 1.33x too large — the *ratios*, *durations* and *easings* would be unaffected.
- Shadow parameters (see above).
- Font family and weights.
- Exact opacity of the faded week edge cells (inferred from luminance of differently
  coloured glyphs, so not a clean opacity reading).
- Anything about the control-centre popup beyond its existence.
- Whether a hover-out *from the hover state* differs from a hover-out from the week
  state — only the former appears in isolation in the video.
