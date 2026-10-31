# BONEBOUND

A classic 55HP Monk farmer for **Guild Wars**, built with **GWAu3** and an **ImGui** interface.

Current version: **0.4.0**

## Farm locations

- **Bergen Hot Springs** - working undead farm in Hard Mode.
- **Gates of Kryta** - planned; shown disabled in the farm menu.

## Features

- Automatic character discovery and selection.
- Enchantment upkeep, farming route, loot collection, map-loading checks, and recovery.
- Independent Blue, Purple, Gold, and Green pickup options.
- Optional bones, dust, coins, dyes, Decayed Orr Emblems, lockpicks, and festival items.
- Full stacks of 250 bones or dust deposited into regular storage; partial stacks retained.
- Golds stored unidentified by default, or identified and sold when enabled.
- Minor, Major, and Superior Vigor protection after identification: the whole armor item is stored, preserving its rune.
- ID-kit checks before identification, short activity updates, and detailed local logs.

## Requirements

- AutoIt 3, **32-bit**.
- A Guild Wars Monk with Hard Mode unlocked and access to Bergen Hot Springs.
- The 55HP equipment setup, including the -50 HP Grim Cesta.
- Monk/Dervish skills required by the build below.
- An identification kit when using Identify & Sell Golds.

The required GWAu3 API and 32-bit ImGui runtime are included. Keep Runtime and Assets beside Bonebound.au3.

## Start

1. Download or clone this repository and extract the complete folder.
2. Log into your Monk in Bergen Hot Springs with a solo party and the 55HP set equipped.
3. Run **Start.cmd** and accept the administrator prompt.
4. Select your character and click **ATTACH**. Use **REFRESH** if needed.
5. Choose pickup preferences, then click **START FARM**.

**FINISH RUN** completes the current run and stops in Bergen. **STOP** cancels the current operation.

## Build

Template: `Owol0IO8TCVr4UPYvGkUCAAgoPkH`

| Slot | Skill |
| --- | --- |
| 1 | Protective Spirit |
| 2 | Mystic Regeneration |
| 3 | Shield of Judgment |
| 4 | Blessed Signet |
| 5 | Empty; reserved for a future addition |
| 6 | Blessed Aura |
| 7 | Essence Bond |
| 8 | Balthazar's Spirit |

## Inventory behavior

**Identify & Sell Golds** is off by default. Unchecked stores session-collected gold gear without identifying it. Checked identifies and sells eligible gold gear, except Vigor-bearing armor, which is stored. Equipment and customized items are protected.

Pickup options do not grant selling permission. Blue, purple, and green items are not automatically identified or sold. Already identified, session-tracked Vigor gear is preserved in storage.

Only equipment confirmed as collected by the current Bonebound session is processed automatically. Existing personal gear and gear left over after restarting the script remain protected. Full bone/dust stacks are deposited independently of that equipment tracking.

Storage uses empty, available regular storage slots. The bot stops for full storage, missing ID kits, the gold limit, unreadable armor modifiers, or an unconfirmed transaction. It does not salvage Vigor runes or buy ID kits automatically.

## Settings and logs

Settings.ini saves your local character and preferences. Activity.log records detailed diagnostics. Both are excluded from Git. Copy Settings.ini into a newly extracted version to retain your choices.

## Validation

AutoIt syntax checks, offline ImGui launch/visibility, saved settings, and simulated inventory/Vigor checks passed. Bergen farming and the merchant workflow have been tested in-game during development. New rarity pickups and Vigor/storage cases still need in-game coverage.

See [CHANGELOG.md](CHANGELOG.md) for updates and [THIRD_PARTY.md](THIRD_PARTY.md) for bundled components.
