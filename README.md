# Audio Game Prototype

## Overview

This is a small music arcade/rhythm game prototype built in Godot 4. The player rotates a character to face incoming musical notes and shoots them at the right time to play a melody. The game records your performance and replays it as a melody at the end of each level.

## How to Run

1. Open the project in Godot 4.
2. Select the `Main.tscn` scene from the project panel.
3. Press the play button to start the game.

## Architecture

- **Main.gd**: Manages the game state, note spawning, timing, and score. It also handles the end-of-level melody playback.
- **Player.gd**: Controls the player character, which rotates to face the mouse and uses raycasts to detect note hits.
- **Note.gd**: Represents musical notes that spawn outside the viewport and fly toward the player. Notes change color (cold → hot → cold) to visually signal the ideal timing window for the player to shoot them.

## Current Status

- The game currently uses a hardcoded test chart with 4 notes.
- The player can rotate to face notes and shoot them using raycasts.
- Timing accuracy is calculated, and the score is updated accordingly.
- At the end of the level, the game replays the notes you hit in chart order.

### Next Steps

- Replace the hardcoded test chart with the real "FirstLevel" melody.
- Add support for multiple levels.
- Improve the UI and visual design.

## Known Limitations

- Only one level exists (hardcoded test chart).
- No complex UI or final visual design.
- The prototype intentionally avoids physical projectiles, using raycasts for simplicity.
- No background music or ambient sound design yet — only the gameplay note-hit sound (pitch-shifted from one base sample) and the final melody playback.
- Timing feedback is currently visual only (the note's color shift) — no numeric/UI display of accuracy or score during play.