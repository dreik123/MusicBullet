# MusicBullet — Project Context

## Project

MusicBullet is a small 2D music-based arcade game prototype made in Godot.

The project is being developed as a portfolio project and as practice for working with modern AI-assisted development workflows.

The long-term goal is to create a small playable prototype that can demonstrate practical game-development skills.

---

## Core Game Concept

The player is fixed near the center of the screen and rotates toward the mouse.

Musical notes appear around/away from the player and move toward the player.

The player shoots at notes.

When a projectile hits a note:

1. The note is considered played.
2. The corresponding musical pitch should be played.
3. Information about the played note is stored.
4. Timing accuracy is calculated.
5. The score is increased.

At the end of a level, the notes actually played by the player are replayed in chart order as a melody. Missed notes are represented by silence.

The game is intended to eventually support multiple musical tracks, but the current prototype focuses on one hardcoded test chart.

---

## Current Prototype Scope

Current prototype focuses on:

- one musical track (hardcoded test chart with 4 notes);
- one Player (CharacterBody2D, rotates to face mouse, uses raycast for note detection);
- notes (Area2D, spawns outside viewport, flies toward player, color modulation based on distance);
- note collision detection (raycast hitscan);
- timing data (accuracy calculation, error tracking);
- score (based on timing accuracy);
- recording played notes (stored in `recorded_notes` array);
- melody playback (replays recorded notes in chart order with pitch scaling).

No complex UI or final visual design is required yet. The prototype intentionally avoids physical projectiles for simplicity.

---

## Current Architecture

### Main

`Main.tscn`

Root node:

`Node2D`

`Main.gd` is responsible for:

- global music time;
- melody data (hardcoded test chart with 4 notes);
- spawning notes (using line-rectangle intersection for spawn position);
- recorded notes (stored in `recorded_notes` array);
- score (based on timing accuracy);
- note travel timing;
- level end detection (all notes spawned and no active notes left);
- melody playback (replays recorded notes in chart order with pitch scaling).

---

### Player

Player is a `CharacterBody2D`.

Player:

- stays in a fixed position;
- rotates toward the mouse;
- uses raycast (hitscan) to detect note collisions (no physical projectiles);
- has a `Marker2D` called `Muzzle` for raycast origin;
- plays note sounds on hit with pitch scaling.

Current important script concepts:

```text
Player
 └── Muzzle