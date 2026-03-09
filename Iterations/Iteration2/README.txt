How to run
- Godot 4.6.x: Import the folder as a project (project.godot).
- Run: starts in Lobby.

Controls
- WASD / Arrow keys to move.
- Gun auto-fires at the nearest enemy.

Gameplay
- 10 waves. Each wave lasts 30 seconds (wave timer).
- Enemies spawn around the arena and chase you; contact deals damage.
- Enemies drop gold pickups on death.
- Between waves, a shop panel appears (game pauses). Spend gold on:
  - Damage (+5 per purchase)
  - Attack speed (+10% per purchase)
- End of run: you get gems (2 per wave completed + 10 bonus if you clear wave 10).
- Lobby: spend gems on permanent +10% damage or +10% attack speed.

Notes
- This is intentionally "code-first": visuals are just collision shapes.
- Save data stored at user://save.json
