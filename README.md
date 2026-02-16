# muteCat UF

`muteCat UF` is a lightweight oUF-based unit frame addon for WoW Retail.
It provides custom `player`, `target`, and `focus` frames, a custom player castbar, and a class-resource bar with Edit Mode support.

Version: `0.1.1`
Interface: `120001`

## Features

- Custom unit frames for:
  - `player`
  - `target`
  - `focus` (half-width layout)
- Custom player castbar:
  - integrated cast icon
  - class-colored castbar
  - movable/resizable via Edit Mode
- Secondary class resource bar (oUF `ClassPower`):
  - only enabled for classes that use class resources
  - class/spec-specific position and size storage
  - optional suppression in vehicle
  - optional suppression while mounted outside dungeon/raid
  - configurable tick and border styling
- Unit text and colors:
  - abbreviated health values
  - class/reaction-based name colors
  - custom neutral and hostile NPC reaction colors
- Player status indicators:
  - combat icon
  - resting icon
- Blizzard frame suppression for overlapping default UI elements:
  - player/target/focus unit frames
  - target-of-target and focus-target
  - Blizzard cast bars
  - boss frames

## Edit Mode Integration

The addon uses `LibEditMode` and exposes movable/resizable anchors for:

- player frame
- target frame
- focus frame
- castbar (position + width/height)
- secondary resource bar (position + width/height)

Settings are stored in `muteCatUFDB`.

## Installation

Copy the addon folder to:

`World of Warcraft\_retail_\Interface\AddOns\muteCat UF`

Make sure the folder name matches the TOC (`muteCat UF.toc`).

## Dependencies

Bundled in `Libraries/`:

- `oUF`
- `LibEditMode`
- `LibSharedMedia-3.0`
- `LibStub`
- `CallbackHandler-1.0`

## Notes

- Run `/reload` after updates.
- This addon targets WoW Retail.
