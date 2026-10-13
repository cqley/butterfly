# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.outfoxxed.me/) desktop shell for a Wayland compositor (wlroots-based,
via `Quickshell.Wayland` / layer-shell). It renders a single pill-shaped top-bar widget (`components/pill`)
that expands into different panels (launcher, power menu, wallpaper picker, network menu, brightness,
calendar, media controls, notifications, polkit auth) depending on state. Entirely QML, no build step.

## Commands

- Run the shell: `quickshell` or `qs` (both on PATH via nix). Quickshell auto-loads `shell.qml` from this
  directory when run with no arguments from here, or via `qs -p ~/.config/quickshell`.
- Reload after edits: Quickshell watches files and live-reloads; if state gets stuck, kill and restart the
  `quickshell`/`qs` process.
- Toggle a panel from a terminal/keybind via IPC: `qs ipc call <target> toggle`, e.g. `qs ipc call launcher toggle`,
  `qs ipc call power toggle`, `qs ipc call network toggle`, `qs ipc call brightness toggle`,
  `qs ipc call wallpaper toggle`, `qs ipc call record toggle`, `qs ipc call mic toggle`, `qs ipc call battery toggle`.
  Some expose extra calls, e.g. `qs ipc call network status`, `qs ipc call polkit status`.
- There is no lint/test/build tooling in this repo (no package.json, no CI). Validate changes by running
  `quickshell` directly and watching stderr for QML warnings/errors.

## Architecture

### Singletons own state, components only render it

Every feature has a `pragma Singleton` QML file (e.g. `Net.qml`, `Power.qml`, `Launcher.qml`, `Media.qml`,
`Battery.qml`, `Mic.qml`, `Record.qml`, `Brightness.qml`, `Wallpaper.qml`, `Notifs.qml`) that holds all
state and logic — `open` flags, data fetched via `Quickshell.Io.Process`, timers, polling. The matching
`*Menu.qml` / plain component (e.g. `NetMenu.qml`, `PowerMenu.qml`) is a dumb view bound to that singleton's
properties via `shown`/`ready` props (see `components/core/Fade.qml` pattern below). Never put state that
needs to survive a component being torn down inside the view component — put it in the singleton.

Singletons talk to the outside world almost exclusively by spawning `Process` elements (nmcli, upower,
brightnessctl-equivalents, etc.) and parsing stdout via `StdioCollector`, rather than linking native
libraries. When adding a feature that shells out, follow the existing pattern in `components/network/Net.qml`:
one `Process` per operation, state machine driven by `phase`/`busy`/`pending` properties, a `Timer` for
polling/timeouts.

### `Modal` is the single source of truth for "what's open"

`components/core/Modal.qml` is a singleton registry. Each panel singleton registers itself once at
`Component.onCompleted` in `components/pill/Slot.qml`'s parent (see `shell.qml` → `Pill.qml`
`Component.onCompleted`: `Modal.register("launcher", Launcher)`, etc.). Opening one panel should call
`Modal.claim(name)` (see `Net.qml`, `Launcher.qml` `onOpenChanged`), which closes every other registered
panel except polkit (polkit auth takes priority and blocks other panels from claiming focus). `Modal.any`
drives whether the outer window grabs exclusive keyboard focus and expands its hit region
(see `shell.qml`'s `win.mask`/`WlrKeyboardFocus`).

### `Pill.qml` is the layout brain

`components/pill/Pill.qml` computes the pill's animated target width/height (`targetW`/`targetH`) as one
big chain of ternaries keyed on which singleton is `open`/`alert`/`hot` — polkit auth > notification alert >
launcher > power > wallpaper > record > net > brightness > hover-expanded > idle. Every new modal panel
needs a branch added to both `targetW` and `targetH` here, plus a corresponding child item instantiated
inside the `ClippingRectangle` with `shown`/`ready` bindings. Panels fade in/out via `components/core/Fade.qml`
(opacity transition keyed on `shown && ready`), and `ready` is wired to `!root.resizing` so content doesn't
pop in before the pill finishes animating its size (`Theme.settleEps` is the tolerance for "settled").

### `Theme.qml` is the only place with magic numbers/colors

`components/core/Theme.qml` is a flat singleton of ~every pixel size, duration, easing curve, and color used
across components, plus a couple of real config values (`screen`, `terminal`, `wallDir`, `recordDir`,
`font`). There are no per-component stylesheets — new UI should add its constants here rather than
hardcoding literals in a component, both for consistency and because some values are shared/derived
(e.g. `powerW: pwW * pwN + pwGap * (pwN - 1) + pwPad * 2`).

### Reusable primitives in `components/core`

- `Fade.qml` — shown/ready → opacity transition, used by every panel.
- `Modal.qml` — open-panel registry/exclusivity, described above.
- `Pick.qml` / `Wheel.qml` — selection-highlight pill and scroll-wheel list-navigation behavior, used by
  menus with a selectable row list (launcher, power, network, wallpaper).
- `Txt.qml` — themed text element.
- `Rule.qml` — themed divider line.
- `StableImage.qml` — image loader with retry (`Theme.imageRetry`) for sources that may not be ready yet
  (wallpaper thumbnails, album art).
- `Hi.qml` — row highlight/selection marker (pill + accent mark), used inside list rows.

### Multi-screen handling

`shell.qml` uses `Quickshell.Variants` over `Quickshell.screens` filtered to `Theme.screen` (falls back to
the first screen if the named one isn't connected). Each screen gets two `PanelWindow`s: an invisible
exclusive-zone spacer reserving top-bar space, and the actual click-through/interactive window hosting
`Pill`. The interactive window's `mask` switches between the pill's hit region and a full-window region
depending on `Modal.any`, which is how click-outside-to-close and exclusive keyboard focus work without a
separate overlay window.

### IPC

Each toggleable singleton exposes an `IpcHandler` with a stable `target` string (`launcher`, `power`,
`network`, `brightness`, `wallpaper`, `record`, `mic`, `battery`, `polkit`) and usually a `toggle()` method,
callable via `qs ipc call <target> <method>`. This is the integration point for external keybinds
(compositor config, scripts) — don't rename an existing `target` without checking for external callers.
