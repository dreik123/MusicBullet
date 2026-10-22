extends RefCounted

# Converts a MusicXML score into the chart format used by main.gd.
#
# Supported files: .musicxml / .xml (plain) and .mxl (compressed), score-partwise only.
# In MuseScore: File > Export > MusicXML.
#
# Chart entry format:
#   {"time": seconds, "pitches": [MIDI numbers], "duration": seconds}
#
# All parts and staves are merged: everything that starts at the same moment becomes
# one entry (one chord), so a single shot plays all of it. Tied notes are merged into
# one long note. The first note is moved to time 0.
#
# Known limits: repeats and endings are not expanded, grace notes and unpitched
# (percussion) notes are skipped, and all parts are always merged into one chart.

const BEAT_RESOLUTION = 960.0
const DEFAULT_BPM = 120.0
const MIN_DURATION = 0.05
const STEP_SEMITONES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


# Returns {"ok": bool, "error": String, "title": String, "notes": Array}.
static func import_file(path: String) -> Dictionary:
	var result = {"ok": false, "error": "", "title": "", "notes": []}

	var bytes = _read_score_bytes(path, result)
	if bytes.is_empty():
		return result

	var root = _parse_xml(bytes)
	if root.is_empty():
		result["error"] = "The file is not valid XML."
		return result
	if root["name"] != "score-partwise":
		result["error"] = "Unsupported file: expected a MusicXML score-partwise document."
		return result

	var events = []
	var tempo_points = []
	var part_index = 0
	for part in _children(root, "part"):
		_collect_part(part, part_index == 0, events, tempo_points)
		part_index += 1

	if events.is_empty():
		result["error"] = "No pitched notes were found in the file."
		return result

	result["notes"] = _build_chart(events, tempo_points)
	result["title"] = _read_title(root, path)
	result["ok"] = true
	return result


# ---------------------------------------------------------------- file reading

static func _read_score_bytes(path: String, result: Dictionary) -> PackedByteArray:
	var bytes = PackedByteArray()
	if path.to_lower().ends_with(".mxl"):
		bytes = _read_from_mxl(path, result)
	else:
		bytes = FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			result["error"] = "Could not open the file."

	# Strip a UTF-8 byte order mark if there is one.
	if bytes.size() >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF:
		bytes = bytes.slice(3)
	return bytes


static func _read_from_mxl(path: String, result: Dictionary) -> PackedByteArray:
	var zip = ZIPReader.new()
	if zip.open(path) != OK:
		result["error"] = "Could not open the .mxl archive."
		return PackedByteArray()

	var files = zip.get_files()
	var score_path = ""

	# The container file names the real score inside the archive.
	if files.has("META-INF/container.xml"):
		var container = _parse_xml(zip.read_file("META-INF/container.xml"))
		if not container.is_empty():
			var rootfile = _find_first(container, "rootfile")
			if not rootfile.is_empty():
				score_path = rootfile["attrs"].get("full-path", "")

	# Fallback: the first .xml / .musicxml file outside META-INF.
	if score_path == "" or not files.has(score_path):
		score_path = ""
		for file_name in files:
			if file_name.begins_with("META-INF/"):
				continue
			var lower = file_name.to_lower()
			if lower.ends_with(".xml") or lower.ends_with(".musicxml"):
				score_path = file_name
				break

	if score_path == "":
		zip.close()
		result["error"] = "No score was found inside the .mxl archive."
		return PackedByteArray()

	var bytes = zip.read_file(score_path)
	zip.close()
	return bytes


# ------------------------------------------------------------------ XML helpers
# The XML is turned into a simple tree of dictionaries:
#   {"name": String, "attrs": Dictionary, "children": Array, "text": String}

static func _parse_xml(bytes: PackedByteArray) -> Dictionary:
	var parser = XMLParser.new()
	if parser.open_buffer(bytes) != OK:
		return {}

	var root = {}
	var stack = []
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT:
			var node = {"name": parser.get_node_name(), "attrs": {}, "children": [], "text": ""}
			for i in range(parser.get_attribute_count()):
				node["attrs"][parser.get_attribute_name(i)] = parser.get_attribute_value(i)
			if stack.is_empty():
				if root.is_empty():
					root = node
			else:
				stack.back()["children"].append(node)
			if not parser.is_empty():
				stack.append(node)
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if not stack.is_empty():
				stack.pop_back()
		elif node_type == XMLParser.NODE_TEXT:
			if not stack.is_empty():
				var text = parser.get_node_data().strip_edges()
				if text != "":
					stack.back()["text"] += text
	return root


static func _child(node: Dictionary, node_name: String) -> Dictionary:
	for c in node["children"]:
		if c["name"] == node_name:
			return c
	return {}


static func _children(node: Dictionary, node_name: String) -> Array:
	var found = []
	for c in node["children"]:
		if c["name"] == node_name:
			found.append(c)
	return found


static func _child_text(node: Dictionary, node_name: String, default_value: String = "") -> String:
	var c = _child(node, node_name)
	if c.is_empty():
		return default_value
	return c["text"]


static func _find_first(node: Dictionary, node_name: String) -> Dictionary:
	if node["name"] == node_name:
		return node
	for c in node["children"]:
		var found = _find_first(c, node_name)
		if not found.is_empty():
			return found
	return {}


# --------------------------------------------------------------- score reading

# Walks one part and appends every pitched note to `events` as
# {"beat": start in quarter notes, "dur": length in quarter notes, "pitch": MIDI number}.
# Tempo markings are appended to `tempo_points` when `collect_tempo` is true.
static func _collect_part(part: Dictionary, collect_tempo: bool, events: Array, tempo_points: Array) -> void:
	var divisions = 1.0
	var measure_start = 0.0   # in quarter notes
	var open_ties = {}        # MIDI number -> event waiting for its tie to end

	for measure in _children(part, "measure"):
		var pos = 0.0         # position inside the measure, in divisions
		var max_pos = 0.0
		var last_onset = 0.0  # start of the previous note, used by chord notes

		for item in measure["children"]:
			var kind = item["name"]
			if kind == "attributes":
				var divisions_text = _child_text(item, "divisions")
				if divisions_text != "":
					divisions = max(float(divisions_text), 1.0)
			elif kind == "sound":
				if collect_tempo:
					_read_tempo(item, measure_start + pos / divisions, tempo_points)
			elif kind == "direction":
				if collect_tempo:
					var sound = _child(item, "sound")
					if not sound.is_empty():
						_read_tempo(sound, measure_start + pos / divisions, tempo_points)
			elif kind == "backup":
				pos -= float(_child_text(item, "duration", "0"))
			elif kind == "forward":
				pos += float(_child_text(item, "duration", "0"))
			elif kind == "note":
				if not _child(item, "grace").is_empty():
					continue
				var duration = float(_child_text(item, "duration", "0"))
				var onset = last_onset
				if _child(item, "chord").is_empty():
					onset = pos
					last_onset = pos
					pos += duration
				_add_note_event(item, measure_start + onset / divisions, duration / divisions, events, open_ties)
			max_pos = max(max_pos, pos)

		measure_start += max_pos / divisions


static func _add_note_event(note: Dictionary, beat: float, dur_beats: float, events: Array, open_ties: Dictionary) -> void:
	var pitch_node = _child(note, "pitch")
	if pitch_node.is_empty():
		return  # a rest or an unpitched (percussion) note
	if not _child(note, "rest").is_empty() or not _child(note, "cue").is_empty():
		return

	var midi = _midi_from_pitch(pitch_node)

	var tie_start = false
	var tie_stop = false
	for tie in _children(note, "tie"):
		var tie_type = tie["attrs"].get("type", "")
		if tie_type == "start":
			tie_start = true
		elif tie_type == "stop":
			tie_stop = true

	# The end of a tie continues the earlier note instead of starting a new one.
	if tie_stop and open_ties.has(midi):
		var earlier = open_ties[midi]
		if abs(earlier["beat"] + earlier["dur"] - beat) < 0.05:
			earlier["dur"] = beat + dur_beats - earlier["beat"]
			if not tie_start:
				open_ties.erase(midi)
			return

	var event = {"beat": beat, "dur": dur_beats, "pitch": midi}
	events.append(event)
	if tie_start:
		open_ties[midi] = event


static func _midi_from_pitch(pitch_node: Dictionary) -> int:
	var step = _child_text(pitch_node, "step", "C")
	var alter = int(round(float(_child_text(pitch_node, "alter", "0"))))
	var octave = int(_child_text(pitch_node, "octave", "4"))
	return (octave + 1) * 12 + STEP_SEMITONES.get(step, 0) + alter


static func _read_tempo(sound: Dictionary, beat: float, tempo_points: Array) -> void:
	if sound["attrs"].has("tempo"):
		var bpm = float(sound["attrs"]["tempo"])
		if bpm > 0.0:
			tempo_points.append({"beat": beat, "bpm": bpm})


static func _read_title(root: Dictionary, path: String) -> String:
	var title = ""
	var work = _child(root, "work")
	if not work.is_empty():
		title = _child_text(work, "work-title")
	if title == "":
		title = _child_text(root, "movement-title")
	if title == "":
		title = path.get_file().get_basename()
	return title


# ----------------------------------------------------------------- chart output

static func _build_chart(events: Array, tempo_points: Array) -> Array:
	_sort_by_beat(tempo_points)
	if tempo_points.is_empty():
		tempo_points.append({"beat": 0.0, "bpm": DEFAULT_BPM})
	elif tempo_points[0]["beat"] > 0.0:
		tempo_points.insert(0, {"beat": 0.0, "bpm": tempo_points[0]["bpm"]})

	# Everything that starts at the same moment becomes one entry.
	var groups = {}
	for event in events:
		var key = int(round(event["beat"] * BEAT_RESOLUTION))
		var end_beat = event["beat"] + event["dur"]
		if not groups.has(key):
			groups[key] = {"beat": event["beat"], "end_beat": end_beat, "pitches": []}
		var group = groups[key]
		if not group["pitches"].has(event["pitch"]):
			group["pitches"].append(event["pitch"])
		group["end_beat"] = max(group["end_beat"], end_beat)

	var keys = groups.keys()
	keys.sort()

	var first_time = _beats_to_seconds(groups[keys[0]]["beat"], tempo_points)
	var chart = []
	for key in keys:
		var group = groups[key]
		var start = _beats_to_seconds(group["beat"], tempo_points)
		var finish = _beats_to_seconds(group["end_beat"], tempo_points)
		var pitches = group["pitches"].duplicate()
		pitches.sort()
		chart.append({
			"time": _round4(start - first_time),
			"pitches": pitches,
			"duration": _round4(max(finish - start, MIN_DURATION)),
		})
	return chart


# Converts a position in quarter notes to seconds, following the tempo changes.
static func _beats_to_seconds(beat: float, tempo_points: Array) -> float:
	var seconds = 0.0
	var count = tempo_points.size()
	for i in range(count):
		var segment_start = tempo_points[i]["beat"]
		var segment_end = beat
		if i + 1 < count:
			segment_end = min(beat, tempo_points[i + 1]["beat"])
		if segment_end > segment_start:
			seconds += (segment_end - segment_start) * 60.0 / tempo_points[i]["bpm"]
		if i + 1 < count and beat <= tempo_points[i + 1]["beat"]:
			break
	return seconds


static func _sort_by_beat(items: Array) -> void:
	for i in range(1, items.size()):
		var current = items[i]
		var j = i - 1
		while j >= 0 and items[j]["beat"] > current["beat"]:
			items[j + 1] = items[j]
			j -= 1
		items[j + 1] = current


static func _round4(value: float) -> float:
	return round(value * 10000.0) / 10000.0
