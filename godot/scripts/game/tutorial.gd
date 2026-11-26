class_name Tutorial
extends Node
## Tutorial: zeigt Schritt für Schritt Aufgaben an und öffnet Türen, sobald eine Aufgabe erledigt ist.

const T := 45.0

var game: Game
var steps: Array
var doors: Array
var index := 0
var shown_at := 0.0
var done_at := 0.0
## Welche Gegnerarten in diesem Durchlauf besiegt wurden ("" = Übungsscheibe)
var defeated := {}
## Am PC unten über dem dunklen Boden, am Handy oben (unten liegen die Touch-Buttons)
var y := 466.0

var _box: Panel
var _style: StyleBoxFlat
var _text: Label
var _check: TextureRect
var _keys := {}


func setup(g: Game, step_list: Array, door_list: Array, layer: CanvasLayer, touch: bool, weapon_name: String) -> void:
	game = g
	steps = step_list
	doors = door_list
	y = 122.0 if touch else 466.0
	_keys = { "LAUFEN": "< >" if touch else "PFEILTASTEN", "SPRINGEN": "^" if touch else "LEERTASTE", "HIEB": "X", "WAFFE": weapon_name }
	_box = Panel.new()
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.043, 0.043, 0.051, 0.88)
	_style.set_border_width_all(3)
	_box.add_theme_stylebox_override("panel", _style)
	layer.add_child(_box)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 12)
	_text.add_theme_constant_override("line_spacing", 9)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_box.add_child(_text)
	_check = TextureRect.new()
	_check.texture = Art.tex("check")
	_check.stretch_mode = TextureRect.STRETCH_SCALE
	_box.add_child(_check)
	_check.size = Vector2(27, 21) * 1.2
	_show(0)


func fill(t: String) -> String:
	for k in _keys:
		t = t.replace("{%s}" % k, _keys[k])
	return t


func hide_box() -> void:
	_box.visible = false


func _show(i: int) -> void:
	index = i
	done_at = 0
	_check.visible = false
	if i >= steps.size():
		_box.visible = false
		return
	_box.visible = true
	_text.text = fill(steps[i]["text"])
	_text.add_theme_color_override("font_color", Color.WHITE)
	_style.border_color = UI.YELLOW
	var size := _text.get_minimum_size()
	_box.size = Vector2(maxf(420, size.x + 110), size.y + 30)
	_box.position = Vector2(480 - _box.size.x / 2, y - _box.size.y / 2)
	_text.position = Vector2.ZERO
	_text.size = _box.size
	_check.position = Vector2(16, _box.size.y / 2 - _check.size.y / 2)
	_box.pivot_offset = _box.size / 2
	_box.scale = Vector2(0.9, 0.9)
	_box.create_tween().tween_property(_box, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	shown_at = game.now


func _is_done(step: Dictionary, now: float) -> bool:
	var d: Dictionary = step["done"]
	match d["type"]:
		"col": return game.player.position.x > d["col"] * T
		"leaves": return game.collected >= d["count"]
		"checkpoint": return game.checkpoint_index >= 0
		"defeat": return defeated.has(d["kind"])
		"timer": return now - shown_at > d["ms"]
	return false


func tick(now: float) -> void:
	if index >= steps.size():
		return
	var step: Dictionary = steps[index]
	var px := game.player.position.x
	# Wer eine Aufgabe ohne Tür überspringt, bekommt einfach die nächste angezeigt
	if not done_at and not step.get("opens_door", false) and index + 1 < steps.size() and px > steps[index + 1]["at"] * T + T:
		_show(index + 1)
		return
	if not done_at and px < step["at"] * T:
		return
	if not done_at and _is_done(step, now):
		done_at = now
		Sfx.play("checkpoint")
		_text.add_theme_color_override("font_color", Color("#a6ff8a"))
		_style.border_color = Color("#6cff6c")
		_check.visible = true
		if step.get("opens_door", false):
			_open_next_door()
	if done_at and now - done_at > 900:
		_show(index + 1)


func _open_next_door() -> void:
	for d in doors:
		if d["open"]:
			continue
		d["open"] = true
		var img: Sprite2D = d["img"]
		img.texture = Art.tex("door-open")
		await get_tree().create_timer(0.25).timeout
		(d["body"] as Node).queue_free()
		game.fx.dust(img.position - Vector2(0, 20), 10)
		var tw := img.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(img, "position:y", img.position.y - 190, 0.6)
		tw.tween_property(img, "modulate:a", 0.15, 0.6)
		return
