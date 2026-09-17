# Three-part campaign

A successful run lasts exactly 900 seconds of active play. Pause menus, item choices, and level-up choices pause the clock as before.

| Part | Active-play slot | Boss |
| --- | --- | --- |
| Mushroom Forest | 00:00–05:00 | Existing fox boss |
| Crimson Citadel | 05:00–10:00 | Inferno Dragon |
| Obsidian Obelisk - The Darkest Darkness | 10:00–15:00 | Obsidian Death |

Each part has ten 30-second waves. The boss spawns at the start of wave 10, leaving the last 30 seconds for the fight and (in the first two areas) walking into the portal. The old two-second between-wave gaps are removed to meet the requested exact duration; the forest's enemy roster, special wave patterns, spawn intervals, stats, and fox artwork remain unchanged.

The first two bosses create a portal at their death location. A portal arms after 0.6 seconds and activates when the player walks within 48 units. Its golden ring is visible on both maps, including at the minimap rim when distant. Missing the boss/portal deadline loses the run. Entering early teleports immediately; the next area's waves begin at its fixed five-minute boundary. Defeating the final boss early stops spawning, but surviving existing enemies until 15:00 is still required for victory. Death or abandonment can end a failed run earlier.

The same live player travels between areas. Current health, level, XP, items, weapons, upgrades, pets, and ongoing power-up durations are retained. Enemies, hostile attacks, old world pickups, and temporary world effects are cleared; new area pickups are populated and map exploration resets.

## New enemies

All three regular enemy types cycle through every wave of their area. Minibosses appear on waves 4 and 7 (01:30 and 03:00 into that area's slot).

| Area | Enemy | Behavior |
| --- | --- | --- |
| Crimson Citadel | Dragon | Holds range and fires a spread of firebolts |
| Crimson Citadel | Fire Golem | Slow pursuit and a ground slam with a warning circle |
| Crimson Citadel | Fire Elemental | Circles the player and launches aimed bolts |
| Crimson Citadel | Magma Sentinel (miniboss) | Large warned ground slams |
| Crimson Citadel | Elder Drake (miniboss) | Wider five-bolt breath attacks |
| Crimson Citadel | Inferno Dragon (boss) | Seven-bolt breath and three ground eruptions |
| Obsidian Obelisk | Ghost | Alternates slow drifting with fast translucent pursuit |
| Obsidian Obelisk | Void Wisp | Orbits at range and shoots void bolts |
| Obsidian Obelisk | Reaper | Aims a visible charge line, then rushes forward |
| Obsidian Obelisk | Dread Knight (miniboss) | Heavy warned charges |
| Obsidian Obelisk | Banshee Queen (miniboss) | Radial bolts and a warned spectral blast |
| Obsidian Obelisk | Obsidian Death (boss) | Radial volleys, ground blasts, and warned charges |

Health, contact damage, attack damage, and spawn intervals respect the original three difficulty selections. Existing burn, curse, freeze, slow, knockback, XP, and boss-damage item mechanics apply. Bosses and minibosses are exempt from regular enemy-cap eviction. Existing fastest-fox-kill statistics retain their prior meaning; a difficulty win now requires all three bosses.

## Artwork

Built-in imagegen was used with the user's painterly storybook style. Production assets are in `assets/campaign/`; final prompts are in `docs/campaign-art-prompts.md`. The two creature sheets retain their alpha channels. Godot loads all images as imported Texture2D resources, and AtlasTexture regions select individual enemies. New floor textures use mirrored repetition for continuous tile boundaries.

## Verification

Run `./tests/run_campaign.ps1` from PowerShell. This creates a separate project under `Temp/campaign-verification` with a separate save namespace, imports assets, and runs the real GLES3 Compatibility renderer with verbose logging.

The test accelerates the campaign clock through all 30 wave boundaries and verifies three bosses, four miniboss encounters, every area roster, all difficulty health/damage/spawn multipliers, status effects, attack warning/damage/expiry, walking through portals, preserved health/upgrades, exact 900-second victory, live-boss and ignored-portal timeouts, restart and scene cleanup. It captures area, portal, and victory screenshots and exits normally. Any error, warning, RID leak, ObjectDB leak, resource warning, or orphan node fails verification. This is automated integration testing, not a substitute for subjective full-run balance testing.

## Debug starting point

Edit DEBUG_STARTING_STAGE and DEBUG_STARTING_WAVE near the top of scripts/game_constants.gd:

- Stage 1: Mushroom Forest (normal default).
- Stage 2: Crimson Citadel, starting at 05:00.
- Stage 3: Obsidian Obelisk, starting at 10:00.
- Wave 1: the first wave of the selected stage.
- Wave 10: jump directly to that stage's boss (04:30, 09:30, or 14:30).

Start or retry a run after editing. The correct area, roster, and campaign clock load immediately without waiting or using a portal. Skipped bosses/waves count as completed for this debug run so later portals and victory still work. You begin with the normal starting character/loadout, not simulated upgrades from skipped areas. Difficulty selection is unchanged. Restore both values to 1 for a normal full run.
