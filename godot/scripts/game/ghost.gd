class_name Ghost
extends Node2D
## Geist der Bestzeit: eine durchsichtige Figur, die den besten Lauf in diesem Level nachläuft.
## Aufnahme: alle STEP ms Position, Bild und Blickrichtung (flach in einem Array: x, y, bild, richtung).

const STEP := 50.0
const FRAMES := ["", "-i", "-w1", "-w2", "-j"]

var samples: Array = []
var best_time := 0.0
var _id := ""
var _view: Sprite2D


func setup(data: Dictionary, player_height: float) -> void:
	samples = data.get("s", [])
	best_time = float(data.get("t", 0.0))
	_id = str(data.get("c", "schueler"))
	if not Art.has("char-" + _id):
		_id = "schueler"
	z_index = 9
	_view = Sprite2D.new()
	_view.texture = Art.tex("char-" + _id)
	_view.scale = Vector2.ONE * Chars.display_scale(Chars.get_char(_id))
	_view.position = Vector2(0, player_height / 2 + 1)
	_view.modulate = Color(0.6, 0.85, 1.0, 0.38)
	add_child(_view)


func tick(now: float) -> void:
	var i := int(now / STEP)
	if (i + 1) * 4 >= samples.size():
		visible = false  # Geist ist im Ziel
		return
	var f := fmod(now, STEP) / STEP
	position = Vector2(lerpf(samples[i * 4], samples[i * 4 + 4], f), lerpf(samples[i * 4 + 1], samples[i * 4 + 5], f))
	var frame: String = FRAMES[clampi(int(samples[i * 4 + 2]), 0, FRAMES.size() - 1)]
	_view.texture = Art.tex("char-" + _id + frame)
	_view.offset = Vector2(0, -_view.texture.get_height() / 2.0)
	_view.flip_h = int(samples[i * 4 + 3]) < 0


## Ein Bild für die Aufnahme bestimmen (wie Player._draw_view)
static func frame_code(on_ground: bool, moving: bool, now: float) -> int:
	if not on_ground:
		return 4
	if moving:
		return 2 if int(now / 95) % 2 else 3
	return 1 if int(now / 520) % 2 else 0
