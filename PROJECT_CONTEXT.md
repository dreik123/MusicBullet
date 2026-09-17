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

At the end of a level, the notes actually played by the player should be played back as a melody.

The game is intended to eventually support multiple musical tracks, but the current prototype focuses on one track.

---

## Current Prototype Scope

Current prototype focuses on:

- one musical track;
- one Player;
- notes;
- projectiles;
- note collision;
- timing data;
- score;
- recording played notes.

No complex UI or final visual design is required yet.

---

## Current Architecture

### Main

`Main.tscn`

Root node:

`Node2D`

`Main.gd` is responsible for:

- global music time;
- melody data;
- spawning notes;
- recorded notes;
- score;
- note travel timing.

---

### Player

Player is a `CharacterBody2D`.

Player:

- stays in a fixed position;
- rotates toward the mouse;
- shoots projectiles;
- has a `Marker2D` called `Muzzle`.

Current important script concepts:

```text
Player
 └── Muzzle