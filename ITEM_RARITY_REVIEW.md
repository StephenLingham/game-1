# Item rarity review

All 83 treasure items reviewed against the implemented effects in game_constants.gd, game_state.gd, player.gd, enemy.gd, pet.gd, minimap.gd and powerup_pickup.gd. Judgments consider one copy, broad usefulness, reliability, scaling, synergies and costs. Identical effects receive identical tiers. Permanent effect descriptions mean the current run, not meta-progression.

## Chest selection

Each chest draws up to three distinct eligible items without replacement. Per-item weights: Common 100, Uncommon 50, Rare 20, Epic 7, Legendary 2. Thus one common item is 50 times as likely as one legendary on the initial draw. Actual tier shares depend on unlocked, sealed and unique held items; if only a few eligible items remain, those items can all appear. No duplicate choices, locked/sealed items, or already-held unique items. Empty pools offer Skip. Existing gift/weapon upgrade luck rolls and unlock order are unchanged. Closed chests contain no predetermined item, so rarity appears when choices are revealed.

## Tiers

### Common (20)

| Item | Reason |
| --- | --- |
| Nuclear Giraffe | Only +0.1x critical damage; needs critical hits to matter. |
| Wholemeal Sandwich | A modest +10 HP buffer against a 100 HP starting baseline. |
| Grandma’s Hearty Meatloaf | Only 0.1 HP per second; slow recovery. |
| Quantum Socks | Only +5 pixels of pickup reach. |
| Loyal Pet Rock | Reflects 10% damage only after being hit; weak and risky. |
| Sentient Boomerang | Same small critical multiplier bonus as Nuclear Giraffe. |
| Lunchbox of Plenty | Same +10 HP bonus as Wholemeal Sandwich. |
| Vampire Cape | Only a 1% chance to heal 1 HP per eligible hit. |
| Chilling Dust | Only a 1% chance of a single-target slow. |
| Crystal Tracker | Reveals one objective; useful navigation with no combat gain. |
| Pureheart Badge | A modest 10% damage bonus lost whenever injured. |
| Pain Furnace | Uncapped growth is outweighed by 50 extra damage taken per hit. |
| Giant Slayer | Only 10% extra damage against bosses. |
| Hardy Apple | Just +5 max HP. |
| Windlace | Small +5% movement speed bonus. |
| Training Gloves | Small +5% attack speed bonus. |
| Whetstone | Small +5 percentage points of critical chance. |
| Strider's Lesson | One XP per five moving seconds is very slow progression. |
| Mirror Sigil | Reflects damage once per ten seconds; implementation does not block the hit. |
| Spirit Lantern | A 1% proc fires five fixed 10-damage spirits; low expected damage. |

### Uncommon (28)

| Item | Reason |
| --- | --- |
| Slippery Banana Peel Dispenser | Reliable +10% movement speed for dodging and collecting. |
| Drunken Pirate’s Bottomless Rum | Reliable +10% damage across the build. |
| Friendly Spoon | Five flat armor meaningfully reduces repeated small hits. |
| Inflatable Bouncy Castle Armor | Reliable 10% damage reduction, including against larger hits. |
| Bottomless Coffee Thermos | Reliable +10% attack speed also helps on-hit effects. |
| Laser Disco Ball | Ten percentage points of critical chance improves damage and crit effects. |
| The Over-Enthusiastic Megaphone | Identical +10% damage to Pirate Rum; identical rarity. |
| Unstable Hamster Wheel | Identical +10% speed to Banana Peel; identical rarity. |
| Fiery Toaster Attachment | Identical +10% damage to Pirate Rum; identical rarity. |
| Magic 8-Ball of Chaos | Identical critical chance to Disco Ball; identical rarity. |
| Hyperactive Squirrel Acorn Launcher | Identical attack speed to Coffee Thermos; identical rarity. |
| Springy Shoes | Identical +10% speed to Banana Peel; identical rarity. |
| Sentient Piñata Buddy | Reliable 10% XP scaling, especially when acquired early. |
| Cosmic Sausage | Five flat damage benefits every attack, but scales poorly relative to large base hits. |
| Frostbite Needle | A full freeze is useful control, limited by a 1% chance. |
| Cartographer's Lens | Substantially improves exploration, but still requires travel. |
| Sentry Root | Large ceiling requires 60 seconds stationary; moving loses the bonus. |
| Momentum Greaves | Useful speed ceiling, but needs 120 seconds of uninterrupted movement. |
| Trail Medicine | Reliable small healing while doing the normal movement loop. |
| Corpse Charge | Potentially large area damage, but just a 1% on-kill proc. |
| Iron Dumbbell | Identical +5 flat damage to Cosmic Sausage; identical rarity. |
| Vengeance Drum | Stacking damage requires taking hits and lasts only three seconds. |
| Lesson Seed | Ten percent extra XP-drop chance; helps progression and pickup synergies. |
| Menagerie Crate | Three short-lived, fragile pets only when opening a chest. |
| Last Stand Stride | Conditional escape speed; half as strong as Bloodrush Boots. |
| Gift Vacuum | Convenient gift collection, dependent on pickup-radius investment. |
| Chest Vacuum | Convenient chest collection, dependent on pickup-radius investment. |
| Spirit Kennel | Temporary invulnerable pet, held back by 1% on-kill chance and low damage. |

### Rare (15)

| Item | Reason |
| --- | --- |
| Titanblood Core | Health-to-damage conversion scales well with health builds, but is conditional. |
| Ricochet Rune | An extra bounce greatly improves coverage for compatible attacks. |
| Crystal Magnet | Automatically collects the crystal from anywhere, removing the travel cost. |
| Giftforge Sigil | Repeated gifts build lasting flat damage over the run. |
| Close Quarters Core | Up to 30 extra damage per eligible hit, balanced by dangerous proximity. |
| Bloodrush Boots | Large emergency movement boost, contingent on losing health. |
| Legendfinder Compass | Directs the player to a high-value legendary gift. |
| Stillwater Idol | Max-health-scaled recovery is substantial, but requires standing still. |
| Shrapnel Seal | Repeatable area damage on critical hits; needs crit investment. |
| Quake Pulse | Screen-wide defensive control offsets its low 1% proc chance. |
| Longshot Scope | Up to 50% extra damage rewards maintaining safe distance. |
| Glass Canon | Large immediate +50% damage with a severe half-health tradeoff. |
| Stride-to-Fury Boots | Converts movement investment into attack speed; build-dependent scaling. |
| Shockwave Shell | A reliable 20% splash proc adds strong crowd damage. |
| Atlas Eye | Reveals all objectives immediately; broad utility but no direct combat power. |

### Epic (15)

| Item | Reason |
| --- | --- |
| Volley Charm | An extra projectile can multiply output and on-hit opportunities across weapons. |
| Execution Pin | Every eligible hit adds target-max-health damage, scaling especially well against bosses. |
| Vampire Tooth | Heals at least 1 HP on every eligible hit, with further damage-scaled healing. |
| Desperation Brand | Repeatable +10 flat damage growth on low-health crossings; powerful but dangerous. |
| Ember Plague | Spreading burns provide sustained crowd damage beyond the initial target. |
| Bloodletter Prism | Frequent critical hits create strong, repeatable sustain. |
| Trophy Heart | Kill scaling can grant up to +100 HP per copy. |
| Warpath Ledger | Kill scaling grants up to +100% damage per copy. |
| Crowd Fang | Flat damage grows naturally with the large crowds that threaten the player. |
| Stormlink Fang | Critical-hit chains can spread full hit damage repeatedly through crowds. |
| Echo Trigger | Extra proc attempts improve many offensive, defensive and progression effects together. |
| Catastrophe Die | 20x damage at 2% chance is roughly +38% expected damage before overkill and synergies. |
| Mega Magnet | Repeated global XP collection greatly improves progression and pickup synergies. |
| Wave Blessing | Free permanent-in-run stat growth after every completed wave. |
| Pain Lottery | Uncapped bonuses from taking damage become very strong with armor and healing. |

### Legendary (5)

| Item | Reason |
| --- | --- |
| Vitality Sap | Five HP per XP pickup turns normal crowd clearing into exceptional sustain. |
| Phoenix Idol | Prevents a fatal hit, fully heals and freezes the crowd; one-use run insurance. |
| Hex Nails | Deals 25% target max HP per second without a boss exemption; one active curse per copy. |
| Snowball Fang | Each critical hit permanently increases crit chance for the run, rapidly snowballing into reliable crits. |
| Ninja Wizard Cat | Permanent invulnerable companion with 999999 contact damage; exceptional autonomous killing power. |

## Verification

Run `powershell -File tests/run_item_rarity.ps1` (pass `-Godot` for a different Godot console executable). The runner copies the game into Temp/rarity-verification under a different application name, isolating player saves. It checks all 83 rarity assignments, 30,000 seeded weighted draws, 1,000 three-item choices, invalid/duplicate IDs, locked/sealed/unique exclusions, empty pools, real chest collection and item acquisition, every chest card layout, all five inventory colours, catalogue rebuilds, scene transitions, and normal shutdown. It requires real OpenGL Compatibility rendering and rejects warnings, script errors, resource leaks or orphan nodes. Screenshots and full logs remain under Temp.

The renderer test uncovered and fixed an existing catalogue leak: description-only items allocated a stats Label without parenting it. Labels are now allocated only when a stats row is actually shown.
