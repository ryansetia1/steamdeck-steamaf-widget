# Agent notes: steamdeck-steamaf-widget

Standalone KDE Plasma 6 widget (`org.ryan.steamaf`): search Steam games via
[steamAF](https://steamaf.vercel.app) and see the buy verdict, regional prices and HowLongToBeat
times in a floating results "island". Helper: `plasmoid/contents/code/steamaf.py` (stdlib only),
run through the Plasma5Support `executable` engine. API origin: `https://steamaf.vercel.app`
(public endpoints, no keys).

## ⚠️ Keep in sync with Deck Monitor

The same steamAF search is built into the all-in-one
[steamdeck-monitor-widget](https://github.com/ryansetia1/steamdeck-monitor-widget) (bottom row of
the card, left side). **Any change here must be applied there too, and the other way round.
Commit and push every affected repo so they stay in sync.**

| This repo | Counterpart in steamdeck-monitor-widget | Rule |
|---|---|---|
| `plasmoid/contents/code/steamaf.py` | `bin/games_steamaf.py` (imported by the daemon) | byte-identical |
| `plasmoid/contents/ui/VerdictBadge.qml` | `plasmoid/contents/ui/VerdictBadge.qml` | byte-identical |
| `plasmoid/contents/icons/steamaf.png` | `plasmoid/contents/icons/steamaf.png` | byte-identical |
| `plasmoid/contents/ui/main.qml` (island, result rows, detail view) | `plasmoid/contents/ui/GamesSection.qml` (`af*` state, `detail`, `afList`) | adapted, port changes by hand |
| config `currency`, `showMainStory`, `islandStyle`, `islandOpacity` | config group `Games`: `gamesCurrency`, `gamesMainStory`, `gamesIslandStyle`, `gamesIslandOpacity` | same meaning, different keys |

Check identical files with `diff -q`. After changing `steamaf.py`, Deck Monitor's daemon must be
reinstalled and restarted (`systemctl --user restart deck-monitor.service`).

## Notes

- Endpoints used: `/api/search`, `/api/status/snapshot` (batch verdict badges),
  `/api/extension/v1/verdict` (+ `refresh=1` when `needsRefresh`), `/api/hltb`. The steamAF web
  app is a separate private repo (`ryansetia1/steamAF`). Its HLTB scraper lives in
  `lib/hltbCache.ts` (`SEARCH_SEG`).
- Verdict colours match steamAF: worth-it `#34d399`, good-deal `#5eead4`, no-rush `#66c0f4`,
  wait `#fbbf24`. HLTB Main Story is highlighted red `#f87171`.
- Per-result Main Story hours are cached in `~/.cache/steamaf-widget/hltb.json` (30 days, misses
  3 days) because steamAF's `/api/hltb` is rate limited per IP.
- Island: `PlasmaCore.Dialog` with `type: Tooltip` (never takes keyboard focus), positioned by
  hand via `mapToGlobal`. Don't use `visualParent` auto-placement; it flipped the island above
  the widget.
- Install with `./install.sh`, then `systemctl --user restart plasma-plasmashell`.
