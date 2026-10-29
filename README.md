# MusicBullet

A small 2D music-arcade game made in Godot 4.

Musical targets fly toward you from eight directions. Aim, shoot them at the right moment, and at the end of the level you get a score, a rank from F to SSS, and a replay of the melody **you** actually played. You can also load your own music from MuseScore.

<!-- Add a screenshot or a short GIF here, e.g. ![gameplay](docs/gameplay.gif) -->

## How it plays

- **Aim:** move the mouse. The aim snaps to one of 8 directions.
- **Shoot:** the `shoot` input action (see *Project > Project Settings > Input Map* for the binding). The shot is instant and hits the first target on the aimed direction. Only targets that are visible on the screen can be hit.
- **Timing:** a target changes colour as it comes closer: cold, then hottest in the middle of its flight, then cold again at the ring around the player. Shoot when it is hottest for up to 100 points. A target that touches the ring is missed.
- **Targets can be more than one note.** Notes that sound together are one target (one shot plays the whole chord). Very fast notes are merged into a long target with a tail; one shot plays the whole run with its original rhythm.
- **Never too crowded.** At most 4 targets are on the screen at once, and one direction is used by at most 3 targets within 5 seconds. Busy music is simplified by merging targets, the music itself is never changed.
- **Score and rank:** the score is shown at the top. After the level you see the result, the number of hits and a rank (F, E, D, C, B, A, S, SS, SSS) based on the percent of the maximum score.
- **Replay:** the game plays back the melody you hit, in the original rhythm. Targets you missed are silence. Press *Play again* or *Menu* at any time to stop it.
- **Debug:** press **F1** to hear the whole melody as written.

## Run it

1. Install Godot 4.
2. Open the project folder (the one with `project.godot`) in Godot.
3. Press Play (F5). If Godot asks for a main scene, choose `main.tscn`.

## Use your own music

1. In MuseScore open **File > Export > MusicXML** and save a `.mxl`, `.musicxml` or `.xml` file.
2. In the game menu press **Load melody** and choose the file, or drag the file onto the game window while the menu is open.
3. The menu shows the title, the number of targets and the length. Press **Start**.
4. **Built-in melody** brings back the original piece.

Notes about imported music:

- All instruments and staves are merged into one melody. Percussion and grace notes are skipped, tied notes become one long note, tempo changes are followed.
- Repeats and endings are not expanded, the piece is played once as written. Native `.mscz` files are not supported, export MusicXML instead.
- The first note is moved to the start of the level.

## The built-in music

The built-in level is an original piano piece, "FirstLevel" (4/4, 120 BPM, about 34 seconds), written by the author. All sounds come from one piano sample (`note_piano.wav`, middle C). Other pitches are made by changing the playback speed, and each note fades out after the length written in the score.

## Project structure

| File | What it does |
| --- | --- |
| `main.gd` | Game states, menu, score, results and rank, chart processing, spawning, melody replay |
| `player.gd` | Aiming (8 directions), instant shot, sound on hit, scoring |
| `note.gd` | A flying target: movement, colour timing indicator, tail of merged notes |
| `miss_boundary.gd` | The ring around the player |
| `chart_importer.gd` | Reads MusicXML files and converts them into the game's melody format |
| `PROJECT_CONTEXT.md` | Detailed technical notes, mainly for AI coding assistants |

## Design notes

Problems this game had to solve:

- **Too many notes at once.** Notes that start together or very close to each other are merged into one target. The number of targets on the screen and per direction is limited.
- **Spam from one direction.** The direction of a target is not tied to its pitch. Directions are spread out, and the one closest to the previous target is preferred, so the player turns as little as possible.
- **Targets overtaking each other.** Every direction has its own constant speed, and targets that must arrive later simply start farther away.
- **Hitting what you cannot see.** The shot ray is cut at the screen edge.
- **Playing any music.** A converter built into the game reads MusicXML, including several voices, ties, tempo changes and compressed files.

All the limits are constants at the top of `main.gd` (for example `MERGE_GAP`, `MAX_VISIBLE_TARGETS`, `MAX_TARGETS_PER_LANE`, `RANKS`) and can be tuned.

## Known limitations

- Very low notes sound smeared, because one sample is slowed down a lot. A second, lower sample would fix this.
- The aim line is drawn longer than the real shot range.
- The screen layout is calculated once at startup; changing the window size during the game is not handled.
- No pause, and a running level cannot be left.
- Only simple shapes are used for graphics. Custom sprites are planned.

## Next steps

Custom sprites and graphics, a second sample for low notes, more levels with several musical parts (for example melody, bass and drums) and a final mix of everything the player recorded.

## About this project

A learning and portfolio project. The game idea, the music and the design decisions are the author's; the code was written with the help of several AI coding assistants and reviewed and tested by the author.
