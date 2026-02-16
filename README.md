# muteCat UF

Always-on oUF unitframes for `player`, `target`, and `focus`, plus a custom player castbar.

Current freeze version: `0.1.1`

## Features

- Custom `player`, `target`, `focus` frames (focus uses half width).
- Custom player castbar with icon, time text, and Edit Mode controls.
- Edit Mode integration via `LibEditMode`:
  - Move `player`, `target`, `focus`, `castbar`.
  - Adjust castbar `X`, `Y`, `Width`, `Height` (0.5 steps).
- Vehicle-aware player power color.
- Health value abbreviation.
- Class/reaction-based name colors.
- Combat/resting status icons on player.
- Blizzard frame suppression:
  - Player/Target/Focus Blizzard frames.
  - Target-of-target / Focus target.
  - Boss frames.
  - Blizzard cast bars.

## Install

Place the folder in:

`World of Warcraft\_retail_\Interface\AddOns\muteCat UF`

Required TOC:

- `muteCat UF.toc` (folder-name matching)

## Saved Variables

- `muteCatUFDB`
  - Stores Edit Mode layout data (positions/sizes).

## Notes

- If frames look outdated after updates, run `/reload`.
- Castbar position/size is layout-aware and can be changed in Edit Mode.
