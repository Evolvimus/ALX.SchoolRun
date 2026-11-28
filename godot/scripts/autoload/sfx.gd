extends Node
## Chiptune-Soundeffekte, beim Start per Code erzeugt (keine Audiodateien).

const RATE := 22050
const BOOST := 2.4

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build()


func play(sound: String, pitch := 1.0) -> void:
	if Save.data.get("muted", false) or not _sounds.has(sound):
		return
	var player := _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = _sounds[sound]
	player.pitch_scale = pitch
	player.play()


## Blatt eingesammelt – je länger die Serie, desto höher der Ton.
func leaf(combo: int) -> void:
	play("leaf", pow(1.06, mini(combo, 14)))


func toggle_mute() -> bool:
	Save.data["muted"] = not Save.data["muted"]
	Save.persist()
	if not Save.data["muted"]:
		play("click")
	return Save.data["muted"]


# ------------------------------------------------------------------ Klangerzeugung

static func tone(freq: float, dur: float, type := "square", vol := 0.06, slide := 0.0, delay := 0.0) -> Dictionary:
	return { "freq": freq, "dur": dur, "type": type, "vol": vol, "slide": slide, "delay": delay }


static func noise(dur: float, vol := 0.05, delay := 0.0) -> Dictionary:
	return { "freq": 0.0, "dur": dur, "type": "noise", "vol": vol, "slide": 0.0, "delay": delay }


static func seq(notes: Array, step: float, type := "triangle", vol := 0.08) -> Array:
	var out := []
	for i in notes.size():
		out.append(tone(notes[i], step * 1.6, type, vol, 0.0, i * step))
	return out


func _build() -> void:
	_sounds = {
		"jump": _render([tone(330, 0.14, "square", 0.06, 1.9)]),
		"air_jump": _render([tone(440, 0.14, "square", 0.06, 2.0)]),
		"land": _render([noise(0.05, 0.03)]),
		"leaf": _render([tone(660, 0.07, "triangle", 0.09), tone(990, 0.1, "triangle", 0.07, 0.0, 0.05)]),
		"swing": _render([noise(0.07, 0.04)]),
		"heavy_swing": _render([noise(0.1, 0.05), tone(150, 0.1, "square", 0.04, 0.6)]),
		"bonk": _render([tone(120, 0.14, "square", 0.12, 0.45), noise(0.09, 0.08)]),
		"hit": _render([tone(180, 0.1, "square", 0.09, 0.5), noise(0.06, 0.06)]),
		"defeat": _render([tone(520, 0.08), tone(780, 0.12, "square", 0.06, 0.0, 0.07)]),
		"hurt": _render([tone(220, 0.3, "saw", 0.09, 0.35)]),
		"bounce": _render([tone(200, 0.2, "triangle", 0.1, 3.0)]),
		"checkpoint": _render(seq([523, 659, 784, 1047], 0.08)),
		"rustle": _render([noise(0.12, 0.03), noise(0.12, 0.03, 0.18)]),
		"flame": _render([noise(0.45, 0.035)]),
		"blow": _render([noise(0.6, 0.025)]),
		"crunch": _render([noise(0.05, 0.05), tone(140, 0.05, "square", 0.05)]),
		"win": _render(seq([523, 659, 784, 659, 784, 1047], 0.11)),
		"over": _render(seq([392, 330, 262, 196], 0.16, "saw", 0.06)),
		"click": _render([tone(700, 0.04, "square", 0.04)]),
		"intro": _render(seq([392, 523, 659, 784], 0.16, "triangle", 0.06) + [tone(1047, 0.7, "triangle", 0.05, 0.0, 0.64)]),
		"tick": _render([tone(1200, 0.03, "triangle", 0.03)]),
		"pause": _render([tone(520, 0.06, "triangle", 0.06), tone(390, 0.08, "triangle", 0.05, 0.0, 0.06)]),
		"magic": _render(seq([784, 988, 1175, 1568, 1976], 0.06, "triangle", 0.07)),
	}


func _render(parts: Array) -> AudioStreamWAV:
	var length := 0.0
	for p in parts:
		length = maxf(length, p["delay"] + p["dur"])
	var n := int((length + 0.02) * RATE)
	var mix := PackedFloat32Array()
	mix.resize(n)
	for p in parts:
		var start := int(p["delay"] * RATE)
		var count := int(p["dur"] * RATE)
		var vol: float = p["vol"]
		var phase := 0.0
		for i in count:
			var t := float(i) / count
			var env := vol * pow(0.0001 / vol, t)
			var s := 0.0
			match p["type"]:
				"noise":
					s = randf_range(-1.0, 1.0)
				_:
					var f: float = p["freq"] * (pow(p["slide"], t) if p["slide"] > 0.0 else 1.0)
					phase = fmod(phase + f / RATE, 1.0)
					match p["type"]:
						"square": s = 1.0 if phase < 0.5 else -1.0
						"triangle": s = 4.0 * absf(phase - 0.5) - 1.0
						"saw": s = 2.0 * phase - 1.0
			var k := start + i
			if k < n:
				mix[k] += s * env * BOOST
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
