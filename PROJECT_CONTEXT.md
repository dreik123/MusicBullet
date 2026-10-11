# MusicBullet — Project Context

Briefing for AI coding assistants and for future me. Describes the **actual state of the code** at the end of the prototype phase. If code and this file disagree, the code wins — read the real files before editing.

## Project

MusicBullet is a small 2D music/arcade game prototype made in Godot 4 (GDScript).

It is a learning and portfolio project, built in about a month with an AI-assisted workflow. The prototype is finished; it is published as a single playable level. Work on a fuller game (more levels, more musical parts) continues separately.

## Core Game Concept

- The player stands in the middle of the screen and aims with the mouse. Aim snaps to 8 directions ("lanes").
- Musical notes fly in from outside the screen along those 8 lanes toward the player.
- The player shoots an instant ray (hitscan) along the aimed lane. The first note on the ray is hit: its pitch(es) sound immediately.
- A note that touches the "miss ring" around the player counts as missed and disappears.
- At the end of the level the game plays back the melody the player actually hit, in the rhythm of the original chart. Missed notes are silence.

The point of the game: turn real, polyphonic music into gameplay, where the player cannot perform unlimited simultaneous actions. Notes sounding at the same moment are merged into one chart entry and hit together with one shot.

## Music / Chart

- The level is the author's own piano piece "FirstLevel" (4/4, 120 BPM, about 34 seconds). Both hands (treble and bass staves) are merged into one chart.
- Chart format, in `main.gd` as `var notes`:

```gdscript
{"time": 0.5, "pitches": [69], "duration": 0.25}
```

  - `time`: onset in seconds from chart start
  - `pitches`: MIDI note numbers sounding at that onset (several = chord, hit with one shot)
  - `duration`: how long the sound is held before a 0.25 s fade-out
- 76 entries. The chart was generated from the MusicXML score by script, not typed by hand. Chord notes must be attached to the onset of their main note (this was a real bug once: chord notes got shifted by one beat).
- `travel_time` is **not** in the data; `main.gd` adds it to each entry at startup (see Timing).

## Architecture

### `main.gd` (root `Node2D`, scene `main.tscn`)

- Owns the clock `music_time`, the chart `notes`, spawning, `recorded_notes`, `score`, level end and melody playback.
- `_ready()`: finds min/max pitch of the chart, computes each entry's `travel_time`, creates the miss ring (`create_miss_boundary()`), computes per-lane speeds.
- `spawn_due_notes()` / `spawn_note()`: spawn a note when `music_time >= time - travel_time`.
- `check_level_end()`: level ends when all notes are spawned and none are active, or `music_time > last_note_time + 1.0`.
- `play_recorded_melody()`: waits 1 s, then walks the chart; an entry is played if a recorded hit has `orig_time` equal to the entry time (±0.01 s) and contains all its pitches.
- `play_reference_melody()`: debug tool, press **F1** to hear the whole chart as written, independent of hits.
- Helpers used by other scripts: `_snap_angle_to_lane_rad()` (Player), `get_note_spawn_radius()` (Player), `_ray_viewport_exit_distance()` (Player, Main), `get_viewport_entry_ratio()` (Note).

### `player.gd` (`CharacterBody2D`, children: `Muzzle`, `AimLine`, `NoteAudio`)

- Rotates toward the mouse, snapped to the nearest of 8 lanes.
- On the `shoot` input action: raycast from `Muzzle`, length = min(spawn radius + margin, distance to the screen edge), so notes outside the visible area cannot be hit.
- `handle_note_hit()`: plays every pitch of the note, computes timing error / accuracy / score, appends a dictionary to `main.recorded_notes` (keys: `pitches`, `time`, `error`, `accuracy`, `score`, `orig_time`), frees the note.
- `play_note_sound(pitch, duration)`: creates a new `AudioStreamPlayer` per sound with `pitch_scale = 2^((pitch-60)/12)` from the single sample `res://note_piano.wav` (a C4 piano note), holds it for `duration`, fades out over 0.25 s, then frees it. One player per sound lets notes ring over each other.

### `note.gd` (`Area2D`, child `Polygon2D`, group `notes`)

- `setup(spawn_time, pitches, target_position, arrival_time)`: `time` is the **spawn** time (chart time minus travel time); `arrival_time` is the chart time. Direction is fixed at spawn (straight line to the player position).
- Moves at a constant `note_speed`. Removed when it touches the miss ring.
- Colour: `self_modulate` goes cold → hot → cold. Heat peaks in the middle of the note's visible flight and is cold again when the note touches the miss ring. Uses `visible_duration` (time spent on screen, from `get_viewport_entry_ratio`).

### `miss_boundary.gd` (`Node2D`)

- Created from code by `main.gd` and added as a child of the Player (no scene node). Draws the ring (radius `MISS_BOUNDARY_RADIUS`, 100 px). `note.gd` reads the radius from here.

## Timing and geometry model (important, easy to break)

- **Lanes**: 8 lanes, 45° apart, starting at -180° (angle -90° is straight up). A chart entry's lane comes from its **highest** pitch, mapped linearly from the chart's min..max pitch to lane 0..7.
- **Per-lane speed**: `lane_speed = (visible_length + NOTE_SPAWN_MARGIN) / 1.2`, where `visible_length` is the distance from the Player to the screen edge along that lane. Same lane = same speed, so notes on one lane can never overtake each other.
- **Spawn distance**: `lane_speed * travel_time`. A note always needs exactly `travel_time` seconds to reach the player.
- **travel_time per entry**: first entry 3.0 s; others `clamp(remap(gap, 0.25, 1.25, 1.2, 3.0), 1.2, 3.0)` where `gap` is the time since the previous entry. Dense passages get short travel times (fewer notes on screen at once), sparse passages get long ones (more reaction time). The 1.2 in the speed formula is this minimum, so the fastest notes spawn just outside the screen.
- `note_travel_time = 3.5` in `main.gd` is only the lead-in: `music_time` starts at `-3.5`.
- Gameplay clock and chart clock are the same clock: a note arrives at `music_time == chart time`.

## Known issues

- **Scoring is unreliable.** `handle_note_hit()` computes `timing_error = shot_time - note.time`, but `note.time` is the spawn time, not an ideal hit time. Accuracy and score are therefore mostly 0. Nothing else depends on them (melody playback only uses hit/miss), and the score is not displayed yet.
- The aim line is drawn at the full raycast length, not clipped to the screen edge (the ray itself is clipped).
- Very low notes (bass down to about MIDI 36) are made by slowing the C4 sample to 0.25x, which sounds smeared. A second, lower sample would fix it.
- `AudioStreamPlayer` count is not limited; very dense passages create many short-lived players.
- No UI, no restart, no pause, one level only.

## Working conventions for assistants

- GDScript for Godot 4. Tabs for indentation. Use the built-in `remap()`; do not write a custom one. No Godot 3 syntax (e.g. old-style `connect`).
- Do **not** edit `.tscn` files by hand; create nodes from code (as `create_miss_boundary()` does).
- Before adding a function or variable, search the project for an existing one with the same name and edit it in place. Duplicated functions were the most common failure in this project.
- When asked to show existing code, paste it verbatim from the file; never reconstruct it from memory.
- Make small, single-purpose changes and report a diff.
- Do not change timing, scoring, or chart format unless asked. Chart data should be regenerated from the score by script, not edited by hand.
- Dead-code check that worked: count references to every function/variable across all `.gd` files; a symbol with zero uses besides its declaration is unused. Note that `get_viewport_entry_ratio()` looks unused in `main.gd` but is called from `note.gd`.
