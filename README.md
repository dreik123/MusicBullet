# MusicBullet

A small 2D music-arcade prototype made in Godot 4.

Notes of a real piano piece fly toward you from eight directions. Aim, shoot them in time, and at the end of the level the game plays back the melody **you** actually played.

<!-- Add a screenshot or a short GIF here, e.g. ![gameplay](docs/gameplay.gif) -->

## How it plays

- **Aim:** move the mouse. The aim snaps to one of 8 directions ("lanes").
- **Shoot:** the `shoot` input action (see *Project → Project Settings → Input Map* for the binding). The shot is instant: it hits the first note on the aimed lane.
- **Timing:** each note changes colour as it approaches: cold when it enters the screen, hottest in the middle of its flight, cold again when it reaches the ring around the player. The ring is the point of no return: a note that touches it is missed and disappears.
- **Chords:** notes that sound at the same moment in the music are one target. One shot plays the whole chord.
- **End of level:** after the last note, the game replays the music in its original rhythm, but only the notes you hit. Missed notes are silence.
- **Debug:** press **F1** at any time to hear the whole piece as written.

## Run it

1. Install Godot 4.
2. Open the project folder (the one with `project.godot`) in Godot.
3. Press Play (F5). If Godot asks for a main scene, choose `main.tscn`.

## The music

The level is an original piano piece, "FirstLevel" (4/4, 120 BPM, about 34 seconds), written by the author. The game chart was generated from the music score by a script: both hands are merged, and simultaneous notes are grouped into chords.

All sounds come from one piano sample (`note_piano.wav`, middle C). Other pitches are made by changing the playback speed, and each note fades out after the length written in the score.

## Project structure

| File | What it does |
| --- | --- |
| `main.gd` | Game clock, the chart, note spawning, level end, melody playback |
| `player.gd` | Aiming (8 lanes), hitscan shooting, sound on hit, recording your hits |
| `note.gd` | A flying note: movement, colour timing indicator, miss detection |
| `miss_boundary.gd` | The ring around the player (created from code) |
| `PROJECT_CONTEXT.md` | Detailed technical notes, mainly for AI coding assistants |

## Design notes

Some problems this prototype had to solve:

- **Too many notes at once.** Each note's flight time depends on how close it is to the previous note in the music: dense passages get short flights (fewer notes on screen), slow passages get long flights (more time to react).
- **Notes overtaking each other.** Speed is fixed per lane, not per note, and the spawn distance changes instead. Notes on one lane keep their order.
- **Hitting what you can't see.** The shot ray is cut at the screen edge, so off-screen notes cannot be hit.
- **Polyphony vs. one action.** Real music has several notes at once. They are merged into one target, so one shot is enough.

## Known limitations

- Scoring is not reliable yet: accuracy is measured against the wrong reference time, so scores are mostly zero. The score is also not shown on screen. This does not affect the melody playback.
- Only one level. No menu, restart, pause or other UI.
- The aim line is drawn longer than the real shot range.
- Very low notes sound smeared, because one sample is slowed down a lot. A second, lower sample would fix this.

## Next steps

This is the end of the prototype. Plans for a fuller game: more levels, several musical parts (for example melody, bass, drums) with different mechanics per part, and a final mix of everything the player recorded.

## About this project

A one-month learning and portfolio project. The game idea, the music and the design decisions are the author's; the code was written with the help of several AI coding assistants and reviewed and tested by the author.
