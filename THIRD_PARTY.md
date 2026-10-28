# Third-party code

Code or assets adapted from other projects, with source and license. Ideas studied for reference but reimplemented from scratch (no code copied) are not listed here.

| Source | File(s) in this repo | License | What was taken |
|---|---|---|---|
| [caelestia-dots/shell](https://github.com/caelestia-dots/shell) `services/Nmcli.qml` | `quickshell/components/network/Net.qml` | GPL-3.0 | Connection success detected from device state (`active === target`) rather than the `nmcli` exit code; the `needsSecret` match list (`secrets were required`, `no secrets provided`, `802-11-wireless-security.psk`, …, with the `connection activated`/`successfully` bail-out); the `nmcli monitor` event-driven refresh. Reimplemented in this codebase's structure — the `needsSecret` string set is the most closely derived part. |
| [caelestia-dots/shell](https://github.com/caelestia-dots/shell) `services/Players.qml` (`getArtUrl`) | `quickshell/components/media/Media.qml` | GPL-3.0 | The YouTube-thumbnail fallback for players with no `trackArtUrl`: match `xesam:url` against a `youtube.com/watch` URL, extract the 11-character video id, point at `img.youtube.com/vi/<id>/hqdefault.jpg`. Idea and regex adapted; the match was later widened here to cover `youtu.be`, `m.`/`music.` and scheme-less forms. |
| [caelestia-dots/shell](https://github.com/caelestia-dots/shell) `plugin/src/Caelestia/Images/imageanalyser.cpp` (`ImageAnalyser::analyse`) | `quickshell/components/media/ArtColors.qml` | GPL-3.0 | The dominant-colour algorithm: bucket pixels by RGB masked to 5 bits per channel (`& 0xF8`), skip transparent pixels, and take the most populous bucket as the artwork's colour. Ported from C++ to the existing `Canvas` sampler, which previously used a channel mean. The chroma floor, dark-colour lift and second-colour pick around it are this repo's own. |
| [Gakuseei/Ricelin](https://github.com/Gakuseei/Ricelin) `configs/quickshell/pill/Singletons/Players.qml` | `quickshell/components/media/Media.qml`, `quickshell/components/media/MediaPanel.qml` | MIT | Three pieces of MPRIS player handling: dropping `playerctld` proxy players by matching `dbusName`; the "idle player" test (not playing *and* no track title) used to skip empty players when choosing the active one, so a paused player with real metadata still wins; and cache-busting a reused `file:` art path by appending a per-track key as a URL fragment. |

## Open licensing question

This repository has **no `LICENSE` file**. The entries above are GPL-3.0 (plus one MIT entry, which only asks that the notice above be kept), which permits reuse but is copyleft: a distributed derivative has to be GPL-3.0 and carry the notices. Nothing was copied verbatim, but the derivation is close enough to matter while the repo is public. Decide one of:

- add a `LICENSE` (GPL-3.0) and keep this file as the accompanying notice, or
- re-derive the affected logic independently (for `needsSecret`, from `nmcli`'s own source/output) and drop the entry.

Do not leave this unresolved indefinitely.
