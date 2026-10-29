# MusicBullet — Project Context

Briefing for AI coding assistants and for future me. It describes the **actual state of the code**. If the code and this file disagree, the code wins: read the real files before editing.

## Project

MusicBullet is a small 2D music-arcade game made in Godot 4 (GDScript). It is a learning and portfolio project built with an AI-assisted workflow.

Status: the prototype is finished and published. It was then extended into a small complete game: start menu, live score, results screen with a rank, loading any melody from a MusicXML file, and automatic simplification of busy music. Custom sprites are postponed.

## Core game concept

- The player stands in the middle of the screen and aims with the mouse. The aim snaps to 8 directions ("lanes").
- Targets fly in from outside the screen along those lanes toward the player.
- The player shoots an instant ray (hitscan) along the aimed lane. The first target on the ray is hit and its notes sound immediately.
- A target that touches the "miss ring" around the player is missed and disappears.
- When the level ends, the results screen shows the score and a rank, and the game plays back the melody the player actually hit, in the rhythm of the original music. Missed targets are silence.

A target is **not always one note**: simultaneous notes (chords) and very fast runs of notes are merged into one target, so one shot plays all of it.

## Game flow

`main.gd` keeps the state in `playing` and `level_ended`:

1. **Menu** (`show_menu()`): title, melody info, Start, Load melody, Built-in melody (only when a custom melody is loaded), Quit. A red message line shows import errors. Dropping a file on the window loads it while the menu is open.
2. **Playing** (`start_game()`): score label at the top, targets fly, the Player can shoot.
3. **Results** (`end_level()` -> `_show_results()`): rank letter, score, hits (`Hits: a / b`), Play again, Menu. The melody playback starts at the same time and stops when a button is pressed (`_playback_id`).

`F1` plays the whole melody as written (debug).

## Files

| File | Role |
| --- | --- |
| `main.gd` | Root `Node2D` of `main.tscn`. Clock, chart processing, spawning, UI (built from code), score, rank, level end, melody playback |
| `player.gd` | `CharacterBody2D`. Aim snapping, hitscan shot, sound on hit, scoring, recording hits |
| `note.gd` | `Area2D` target. Movement, colour timing indicator, segment tail, ideal hit time |
| `miss_boundary.gd` | `Node2D` created from code and added to the Player. Draws the miss ring |
| `chart_importer.gd` | MusicXML -> chart converter (static functions) |
| `note_piano.wav` | The only sound sample (middle C piano) |

All UI is created in code (`CanvasLayer` + `Control` nodes). Do not edit `.tscn` files by hand.

## Chart pipeline

A melody is an array of entries:

```gdscript
{"time": 0.5, "pitches": [69], "duration": 0.25}   # raw entry: time in seconds
```

`prepare_chart()` turns the raw array into the final targets. **Order matters**:

1. `_compute_lane_geometry()`: speed of every lane and `_visible_time` (the longest time a target stays on the screen).
2. `_merge_fast_notes()`: entries closer than `MERGE_GAP` (0.2 s) become one segment (max `MAX_SEGMENT_LENGTH` = 1.5 s).
3. `_limit_visible_targets()`: no more than `MAX_VISIBLE_TARGETS` (4) targets may start inside one `_visible_time` window; extra ones join the previous target.
4. `_assign_lanes()`: gives each target a lane (see below). A target that cannot be placed without breaking a rule joins the previous target.
5. `travel_time` is added to every target.

A final target looks like this:

```gdscript
{"time": 12.0, "pitches": [60, 64], "duration": 1.3, "lane": 3, "travel_time": 1.8,
 "steps": [{"offset": 0.0, "pitches": [60], "duration": 0.5},
           {"offset": 0.125, "pitches": [64], "duration": 0.5}]}
```

- `steps` are the notes that play when the target is hit (offset = seconds after the start of the target). A normal target has one step with offset 0. `pitches` is the union of all step pitches and is used to match recorded hits.
- Merging never changes the music: every note keeps its exact time and pitch.
- `_default_notes` keeps the untouched raw built-in chart. `prepare_chart()` is always called on a fresh raw copy (`_ready`, `_load_melody`, `_use_built_in_melody`).

### Lane (direction) rules

The lane does **not** depend on pitch. `_assign_lanes()` picks, among the lanes that keep the rules, the one used least in the last `LANE_SPREAD_WINDOW` (5 s); ties go to the lane closest to the previous target.

- One lane has at most `MAX_TARGETS_PER_LANE` (3) targets within `LANE_SPREAD_WINDOW` (5 s).
- At most `MAX_LANES_IN_WINDOW` (2) different lanes are used within `LANE_WINDOW` (1 s). Set it to `LANE_COUNT` to switch this off.

Python simulations on the built-in melody, a dense synthetic piece and a steady stream, on two screen sizes, confirmed all limits (including the exact number of targets visible at the same moment).

## MusicXML importer (`chart_importer.gd`)

`ChartImporter.import_file(path)` returns `{"ok", "error", "title", "notes"}`.

- Formats: `.musicxml`, `.xml` and compressed `.mxl` (read with `ZIPReader`). `score-partwise` only. Export from MuseScore: File > Export > MusicXML.
- Timing follows the MusicXML model: a cursor per measure, `<backup>`/`<forward>`, chord notes share the onset of their main note, `divisions` can change, tempo changes (`<sound tempo>`) are followed.
- Tied notes are merged into one long note. Grace notes and unpitched (percussion) notes are skipped.
- All parts and staves are merged into one chart. The first note is moved to time 0.
- Not supported: repeats and endings (not expanded), `.mscz`, `score-timewise`, choosing a part.
- The algorithm was validated in Python against the real score and ten edge-case tests (voices, ties, tempo, divisions, parts, pickup measure, percussion).

## Timing, geometry and scoring

- **Lane speed**: `lane_speed = (visible_length + NOTE_SPAWN_MARGIN) / 1.2`, where `visible_length` is the distance from the Player to the screen edge along that lane. Same lane, same speed, so targets on one lane never overtake each other.
- **Spawn distance** = `lane_speed * travel_time`, so a target always needs exactly `travel_time` seconds to reach the Player. Targets spawn at `time - travel_time`.
- **travel_time**: first target 3.0 s; others `clamp(remap(gap, 0.25, 1.25, 1.2, 3.0), 1.2, 3.0)` where `gap` is the time since the previous target.
- `note_travel_time = 3.5` is only the lead-in: `music_time` starts at `-3.5`. Game clock and chart clock are the same clock.
- **Colour**: cold -> hot -> cold. The hottest moment is the middle of the visible flight, measured to the miss ring (`get_ideal_time()` in `note.gd`).
- **Score**: `timing_error = shot_time - note.get_ideal_time()`; `accuracy = max(0, 1 - |error| / 0.5)`; points = `round(accuracy * 100)`, so a perfect hit gives 100. `add_score()` in `main.gd` updates the label.
- **Rank**: percent of `targets * MAX_SCORE_PER_NOTE`, thresholds in the `RANKS` constant (SSS 95, SS 90, S 80, A 70, B 60, C 50, D 40, E 25, F 0).
- **Shot range**: the ray stops at the screen edge (`_ray_viewport_exit_distance`), so off-screen targets cannot be hit.
- **Sound**: `play_note_sound(pitch, duration)` creates a new `AudioStreamPlayer` per sound, `pitch_scale = 2^((pitch - 60) / 12)`, holds it for `duration`, fades out in 0.25 s, then frees it. `play_steps()` plays the steps of a hit target with their offsets.
- **Melody playback**: `_collect_playback_events()` builds a time-sorted list from the `steps` of all hit targets (`_was_hit()` matches `orig_time` and pitches); `_play_events()` plays it and can be cancelled.

## Tunable constants

| Constant | Where | Default | Meaning |
| --- | --- | --- | --- |
| `MERGE_GAP` | `main.gd` | 0.2 | fast notes closer than this are merged |
| `MAX_SEGMENT_LENGTH` | `main.gd` | 1.5 | longest segment, seconds |
| `MAX_VISIBLE_TARGETS` | `main.gd` | 4 | targets on screen at once |
| `MAX_TARGETS_PER_LANE` / `LANE_SPREAD_WINDOW` | `main.gd` | 3 / 5.0 | per-lane limit |
| `MAX_LANES_IN_WINDOW` / `LANE_WINDOW` | `main.gd` | 2 / 1.0 | lanes used in a short window |
| `RANKS` | `main.gd` | see above | rank thresholds in percent |
| `TXT_*` | `main.gd` | English | all UI texts |
| `MISS_BOUNDARY_RADIUS` | `miss_boundary.gd` | 100 | miss ring radius |

## Known issues and limits

- Very low notes (bass down to about MIDI 36) are made by slowing the C4 sample to 0.25x, which sounds smeared. A second, lower sample would fix it.
- The aim line is drawn at the full raycast length, not clipped to the screen edge (the ray itself is clipped).
- The colour curve is measured to the Player centre but anchored to the miss ring, so targets enter the screen already slightly warm.
- Lane speeds and the visible-time limit are computed once at startup; changing the window size while running leaves them stale.
- The number of `AudioStreamPlayer` nodes is not limited.
- No pause and no way to leave a running level.
- Importer limits: see the importer section.

## Working conventions for assistants

- GDScript for Godot 4, tabs for indentation. Use the built-in `remap()`. No Godot 3 syntax.
- **Everything written into files must be in English** (code, comments, UI texts, docs).
- Do not edit `.tscn` files by hand; create nodes from code.
- Before adding a function or variable, search the project for an existing one with the same name and edit it in place. Duplicated functions were the most common failure in this project.
- When asked to show existing code, paste it verbatim from the file; never reconstruct it from memory.
- Replacing a whole file overwrites local edits: check `git diff` afterwards.
- Make small, single-purpose changes and report a diff. Do not change timing, scoring or the chart format unless asked.
- Chart data must be generated from the score by script (the importer), not typed by hand. Chord notes belong to the onset of their main note.
- Dead-code check that worked: count references to every function and variable across all `.gd` files. Beware of calls between scripts: `get_viewport_entry_ratio()` is defined in `main.gd` but called from `note.gd`.
- Verify algorithms with a small reference implementation (Python) before porting them to GDScript.
