extends Node
## Chiptune-Musik, per Code komponiert und beim Start nach und nach erzeugt (keine Audiodateien).
##
## Jedes Stück hat Tempo, Tonart, Akkordfolge und Stil. Daraus entstehen Bass, Akkord-Arpeggio,
## Melodie (Teil A, A', B, A') und Schlagzeug. Gerendert wird in kleinen Stücken pro Frame, damit
## nichts ruckelt – auch im Browser ohne Threads. Bis ein Stück fertig ist, bleibt es still.

const RATE := 22050
const CHUNK := 12000  # Samples pro Frame beim Erzeugen

## Stücke: bpm, root (MIDI-Note), mode ("major"/"minor"), chords (Stufen 0–6), style, seed
const TRACKS := {
	"menu": { "bpm": 108, "root": 60, "mode": "major", "chords": [0, 5, 3, 4], "style": "calm", "seed": 11 },
	"ch1": { "bpm": 138, "root": 67, "mode": "major", "chords": [0, 4, 5, 3], "style": "bouncy", "seed": 23 },
	"ch2": { "bpm": 148, "root": 62, "mode": "minor", "chords": [0, 5, 2, 6], "style": "drive", "seed": 37 },
	"ch3": { "bpm": 128, "root": 65, "mode": "major", "chords": [0, 3, 4, 0], "style": "bouncy", "seed": 41 },
	"ch4": { "bpm": 100, "root": 57, "mode": "minor", "chords": [0, 3, 6, 4], "style": "calm", "seed": 53 },
	"ch5": { "bpm": 144, "root": 64, "mode": "minor", "chords": [0, 6, 5, 6], "style": "arp", "seed": 67 },
	"ch6": { "bpm": 124, "root": 58, "mode": "major", "chords": [0, 5, 1, 4], "style": "drive", "seed": 71 },
	"boss": { "bpm": 162, "root": 57, "mode": "minor", "chords": [0, 0, 5, 6], "style": "boss", "seed": 89 },
}
## Reihenfolge, in der die Stücke erzeugt werden (Menü zuerst)
const ORDER := ["menu", "ch1", "boss", "ch2", "ch3", "ch4", "ch5", "ch6"]

const SCALES := { "major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10] }

var _streams := {}
var _queue: Array = []
var _job: Dictionary = {}
var _mix := PackedFloat32Array()  # Mix des Stücks, das gerade entsteht (Mitglied, weil Packed-Arrays als Kopie übergeben werden)
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _current := ""
var _wanted := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80
		add_child(p)
		_players.append(p)
	if "--bot" in OS.get_cmdline_user_args() or "--build-levels" in OS.get_cmdline_user_args():
		return  # Testläufe brauchen keine Musik
	_queue = ORDER.duplicate()


## Stück abspielen (mit Überblendung). "" = Stille.
func play(track: String) -> void:
	_wanted = track
	if track == _current:
		return
	if track != "" and not _streams.has(track):
		# noch nicht fertig: nach vorne in die Warteschlange, startet dann automatisch
		if track in _queue:
			_queue.erase(track)
			_queue.push_front(track)
		_fade_out()
		_current = ""
		return
	_fade_out()
	_current = track
	if track == "":
		return
	_active = 1 - _active
	var p := _players[_active]
	p.stream = _streams[track]
	p.volume_db = -40
	p.play()
	var tw := p.create_tween()
	tw.tween_property(p, "volume_db", target_db(), 0.8)


func _fade_out() -> void:
	var old := _players[_active]
	if old.playing:
		var tw := old.create_tween()
		tw.tween_property(old, "volume_db", -60.0, 0.6)
		tw.tween_callback(old.stop)


## Lautstärke aus den Einstellungen (0–1), Stummschaltung beachten
func target_db() -> float:
	var v: float = Save.data["settings"].get("music", 0.6)
	if Save.data.get("muted", false) or v <= 0.01:
		return -80.0
	return linear_to_db(v * 0.55)


func refresh_volume() -> void:
	var p := _players[_active]
	if p.playing:
		p.volume_db = target_db()


## Welches Stück gehört zu einem Level?
static func track_for(level: Dictionary) -> String:
	if level.get("kind", "") == "boss":
		return "boss"
	var ch: int = level.get("chapter", 1)
	return "ch%d" % clampi(ch if ch > 0 else 1, 1, 6)


# ------------------------------------------------------------------ Erzeugen (nach und nach)

func _process(_delta: float) -> void:
	if _job.is_empty():
		if _queue.is_empty():
			return
		_job = _compose(_queue.pop_front())
	_render_chunk()


## Notenfolge eines Stücks festlegen
func _compose(name: String) -> Dictionary:
	var t: Dictionary = TRACKS[name]
	var rng := RandomNumberGenerator.new()
	rng.seed = t["seed"]
	var beat: float = 60.0 / float(t["bpm"])
	var step: float = beat / 4.0  # Sechzehntel
	var scale: Array = SCALES[t["mode"]]
	var root: int = t["root"]
	var chords: Array = t["chords"]
	var style: String = t["style"]
	var bars := 16
	var notes: Array = []  # [start_s, dur_s, midi, voice, vol]
	var deg := func(d: int, octave := 0) -> int:
		return root + scale[posmod(d, 7)] + 12 * (octave + floori(d / 7.0))
	# Melodie-Phrasen: A und B je 4 Takte, Form A A' B A'
	var phrase := func(variant: int) -> Array:
		var out := []
		for bar in 4:
			var c: int = chords[bar % chords.size()]
			var rhythm: Array = [[0, 4], [4, 2], [6, 2], [8, 4], [12, 4]]
			match rng.randi_range(0, 3):
				1: rhythm = [[0, 2], [2, 2], [4, 4], [8, 2], [10, 2], [12, 4]]
				2: rhythm = [[0, 6], [6, 2], [8, 6], [14, 2]]
				3: rhythm = [[0, 3], [3, 3], [6, 2], [8, 3], [11, 3], [14, 2]]
			var d: int = c + [0, 2, 4][rng.randi_range(0, 2)]
			for r in rhythm:
				if variant == 1 and bar == 3 and r[0] >= 8:
					d = c  # A' endet auf dem Grundton
				elif rng.randf() < 0.7:
					d += [-1, 1, 1, 2, -2][rng.randi_range(0, 4)]
				else:
					d = c + [0, 2, 4, 7][rng.randi_range(0, 3)]
				out.append([bar * 16 + r[0], r[1], d])
		return out
	var a: Array = phrase.call(0)
	var a2: Array = phrase.call(1)
	var b: Array = phrase.call(2)
	var form := [a, a2, b, a2]
	for part in 4:
		for n in form[part]:
			var start: float = (part * 64 + n[0]) * step
			var octave := 1 if style != "calm" else 0
			notes.append([start, n[1] * step * 0.92, deg.call(n[2] + 7 * octave - 7), "lead", 0.055])
	# Bass, Arpeggio, Schlagzeug
	for bar in bars:
		var c: int = chords[bar % chords.size()]
		var t0: float = bar * 16 * step
		var bass_pattern: Array = [0, 8] if style == "calm" else [0, 4, 8, 12] if style != "boss" else [0, 2, 4, 6, 8, 10, 12, 14]
		for i in bass_pattern.size():
			var o := 0 if i % 2 == 0 or style == "calm" else 1
			notes.append([t0 + bass_pattern[i] * step, step * (7.0 if style == "calm" else 1.8), deg.call(c, -2 + o), "bass", 0.11])
		var arp := [0, 2, 4, 7]
		var arp_every := 2 if style in ["arp", "boss"] else 4
		for s in range(0, 16, arp_every):
			var tone: int = deg.call(c + arp[(s / arp_every) % 4], 0)
			notes.append([t0 + s * step, step * arp_every * 0.6, tone, "arp", 0.022 if style != "arp" else 0.03])
		if style != "calm" or bar >= 8:
			for s in 16:
				var kick := s % 8 == 0 or (style in ["drive", "boss"] and s % 4 == 0)
				var snare := s % 8 == 4
				var hat := s % 2 == 0 and style != "calm"
				if kick:
					notes.append([t0 + s * step, 0.09, 0, "kick", 0.16])
				if snare:
					notes.append([t0 + s * step, 0.08, 0, "snare", 0.06])
				elif hat:
					notes.append([t0 + s * step, 0.03, 0, "hat", 0.025])
	_mix = PackedFloat32Array()
	_mix.resize(int(bars * 16 * step * RATE))
	return { "name": name, "notes": notes, "pos": 0 }


## Ein paar Noten pro Frame in den Mix schreiben, am Ende als Schleife speichern
func _render_chunk() -> void:
	var notes: Array = _job["notes"]
	var n := _mix.size()
	var budget := CHUNK
	while budget > 0 and _job["pos"] < notes.size():
		var note: Array = notes[_job["pos"]]
		_job["pos"] += 1
		budget -= _note(n, note)
	if _job["pos"] < notes.size():
		return
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(_mix[i] * 1.8, -1.0, 1.0) * 32767.0))
	_mix = PackedFloat32Array()
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	_streams[_job["name"]] = wav
	for a in OS.get_cmdline_user_args():  # --export-music=ORDNER: Stücke als WAV speichern (Hörproben)
		if a.begins_with("--export-music="):
			wav.save_to_wav(a.get_slice("=", 1).path_join(_job["name"] + ".wav"))
	if "--music-timing" in OS.get_cmdline_user_args():
		print("MUSIC_READY %s %.1fs after %d ms" % [_job["name"], n / float(RATE), Time.get_ticks_msec()])
	var done: String = _job["name"]
	_job = {}
	if done == _wanted and _current != done:
		play(done)


func _note(n: int, note: Array) -> int:
	var start := int(note[0] * RATE)
	var count := int(note[1] * RATE)
	var voice: String = note[3]
	var vol: float = note[4]
	var freq := 440.0 * pow(2.0, (note[2] - 69) / 12.0)
	var phase := 0.0
	var inc := freq / RATE
	var noise := 0.0
	for i in count:
		var k := (start + i) % n  # Ende läuft weich in den Anfang (Schleife)
		var t := float(i) / count
		var s := 0.0
		match voice:
			"lead":
				phase = fmod(phase + inc, 1.0)
				s = (1.0 if phase < 0.25 else -1.0) * vol * (1.0 - t * 0.6) * minf(1.0, i / 60.0)
			"bass":
				phase = fmod(phase + inc, 1.0)
				s = (4.0 * absf(phase - 0.5) - 1.0) * vol * (1.0 - t * 0.5)
			"arp":
				phase = fmod(phase + inc, 1.0)
				s = (1.0 if phase < 0.5 else -1.0) * vol * (1.0 - t)
			"kick":
				phase = fmod(phase + (150.0 * (1.0 - t) + 40.0) / RATE, 1.0)
				s = sin(phase * TAU) * vol * (1.0 - t)
			"snare":
				s = randf_range(-1.0, 1.0) * vol * (1.0 - t) * (1.0 - t)
			"hat":
				if i % 2 == 0:
					noise = randf_range(-1.0, 1.0)
				s = noise * vol * (1.0 - t)
		_mix[k] += s
	return count
