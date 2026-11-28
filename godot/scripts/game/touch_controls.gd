class_name TouchControls
extends Control
## Touch-Steuerung für Handy und Tablet.
##
## Linke Bildschirmhälfte: ein „schwebender“ Stick. Wo der Daumen aufsetzt, erscheint der Stick;
## zieht man weiter als der Rand, wandert er mit. Links/rechts laufen, hoch klettert an der Sprossenwand,
## runter duckt/fällt durch Bretter.
## Rechte Hälfte: zwei große Knöpfe – Springen (groß, außen) und Hieb. Man muss sie nicht genau treffen:
## Jede Berührung rechts zählt für den näheren Knopf, und man kann mit dem Daumen von einem zum
## anderen rollen. Ganz oben (Pause, Anzeigen) reagiert die Steuerung nicht.

const STICK_RING := 66.0
const STICK_KNOB := 30.0
const STICK_TRAVEL := 54.0
const DEAD_X := 16.0
const DEAD_UP := 30.0
const DEAD_DOWN := 36.0
const TOP_FREE := 110.0  # oberer Rand bleibt für Pause und Anzeigen frei

## Stick nach oben (Klettern) – wird nicht als Sprung gewertet
var up := false

var _w := 960.0
var _stick_home := Vector2.ZERO
var _stick_origin := Vector2.ZERO
var _stick_knob := Vector2.ZERO
var _stick_index := -1
var _buttons := {}  # name -> { center, radius, icon, action, index, pressed }
var _weapon_icon: Texture2D
var _used := false  # nach der ersten Benutzung wird der Stick in Ruhe fast unsichtbar
var _k := 1.0       # Größe aus den Einstellungen
var _lefty := false # Linkshänder: Stick rechts, Knöpfe links
var _ring := STICK_RING


func setup(weapon: String) -> void:
	_w = UI.vw()
	size = Vector2(_w, 540)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ins := UI.safe_insets()
	_k = float(Save.data["settings"].get("touch_size", 1.0))
	_lefty = bool(Save.data["settings"].get("lefty", false))
	_ring = STICK_RING * _k
	_stick_home = Vector2(_w - ins.y - 120 * _k if _lefty else ins.x + 120 * _k, 540 - 100 * _k)
	_stick_origin = _stick_home
	_stick_knob = _stick_home
	_weapon_icon = Art.tex("hammer-gold" if weapon == "goldHammer" else "hammer" if weapon == "hammer" else "ruler")
	# Knöpfe von der Ecke aus gemessen (bei Linkshändern gespiegelt)
	var edge := ins.x if _lefty else ins.y
	var jx := edge + 96 * _k
	var ax := edge + 226 * _k
	_buttons = {
		"jump": { "center": Vector2(jx if _lefty else _w - jx, 540 - 108 * _k), "radius": 58.0 * _k, "icon": Art.tex("icon-jump"), "action": "jump", "index": -1, "pressed": false },
		"attack": { "center": Vector2(ax if _lefty else _w - ax, 540 - 78 * _k), "radius": 46.0 * _k, "icon": _weapon_icon, "action": "attack", "index": -1, "pressed": false },
	}
	queue_redraw()


## Alles loslassen (z. B. beim Pausieren)
func release_all() -> void:
	_stick_index = -1
	_stick_origin = _stick_home
	_stick_knob = _stick_home
	_apply_stick(Vector2.ZERO)
	for b in _buttons.values():
		b["index"] = -1
		_set_button(b, false)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Am PC (--touch) dient die Maus als ein Finger
	if Nav.args.has("touch") and not OS.has_feature("mobile"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_touch(99, event.position, event.pressed)
		elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_drag(99, event.position)
		return
	if event is InputEventScreenTouch:
		_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	pos = _local(pos)
	if pressed:
		if pos.y < TOP_FREE:
			return
		if (pos.x > _w * 0.55) if _lefty else (pos.x < _w * 0.45):
			if _stick_index < 0:
				_stick_index = index
				_used = true
				_stick_origin = Vector2(pos.x, minf(pos.y, 540 - _ring - 6))
				_stick_knob = pos
				_update_stick(pos)
		elif (pos.x < _w * 0.5) if _lefty else (pos.x > _w * 0.5):
			var b := _nearest(pos)
			if b["index"] < 0:
				b["index"] = index
				_set_button(b, true)
	else:
		if index == _stick_index:
			release_stick()
		for b in _buttons.values():
			if b["index"] == index:
				b["index"] = -1
				_set_button(b, false)
	queue_redraw()


func _drag(index: int, pos: Vector2) -> void:
	pos = _local(pos)
	if index == _stick_index:
		_update_stick(pos)
		queue_redraw()
		return
	# Daumen rollt von einem Knopf zum anderen
	for name in _buttons:
		var b: Dictionary = _buttons[name]
		if b["index"] != index:
			continue
		for other_name in _buttons:
			var o: Dictionary = _buttons[other_name]
			if other_name == name or o["index"] >= 0:
				continue
			if pos.distance_to(o["center"]) < o["radius"] * 0.9 and pos.distance_to(b["center"]) > b["radius"]:
				b["index"] = -1
				_set_button(b, false)
				o["index"] = index
				_set_button(o, true)
				queue_redraw()
				return


func release_stick() -> void:
	_stick_index = -1
	_stick_origin = _stick_home
	_stick_knob = _stick_home
	_apply_stick(Vector2.ZERO)


func _update_stick(pos: Vector2) -> void:
	var d := pos - _stick_origin
	if d.length() > STICK_TRAVEL * _k:  # Stick wandert mit, wenn der Daumen weiter zieht
		_stick_origin = pos - d.normalized() * STICK_TRAVEL * _k
		d = pos - _stick_origin
	_stick_knob = _stick_origin + d
	_apply_stick(d)


func _apply_stick(d: Vector2) -> void:
	_set_action("move_left", d.x < -DEAD_X)
	_set_action("move_right", d.x > DEAD_X)
	_set_action("move_down", d.y > DEAD_DOWN and absf(d.y) > absf(d.x) * 0.8)
	up = d.y < -DEAD_UP


func _nearest(pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for b in _buttons.values():
		var dist: float = pos.distance_to(b["center"]) / b["radius"]
		if dist < best_d:
			best_d = dist
			best = b
	return best


func _set_button(b: Dictionary, on: bool) -> void:
	if b["pressed"] == on:
		return
	b["pressed"] = on
	_set_action(b["action"], on)


func _set_action(action: String, on: bool) -> void:
	if on and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not on and Input.is_action_pressed(action):
		Input.action_release(action)


## Bildschirmposition → Position in dieser Fläche
func _local(p: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * p


func _draw() -> void:
	# Stick
	var active := _stick_index >= 0
	var a := 1.0 if active else (0.18 if _used else 0.45)
	draw_circle(_stick_origin, _ring, Color(0.05, 0.06, 0.14, 0.45 * a))
	draw_arc(_stick_origin, _ring, 0, TAU, 48, Color(1, 1, 1, 0.35 * a), 3.0)
	for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var tip: Vector2 = _stick_origin + dir * (_ring - 12)
		var side: Vector2 = dir.orthogonal() * 6
		draw_colored_polygon(PackedVector2Array([tip + dir * 6, tip - side, tip + side]), Color(1, 1, 1, 0.3 * a))
	draw_circle(_stick_knob, STICK_KNOB * _k, Color(1, 1, 1, 0.55 if active else 0.25))
	draw_arc(_stick_knob, STICK_KNOB * _k, 0, TAU, 32, Color(1, 1, 1, 0.8 * a), 2.0)
	# Knöpfe
	for b in _buttons.values():
		var on: bool = b["pressed"]
		var c: Vector2 = b["center"]
		var r: float = b["radius"] * (0.93 if on else 1.0)
		draw_circle(c, r, Color(1.0, 0.8, 0.2, 0.55) if on else Color(0.05, 0.06, 0.14, 0.45))
		draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.9 if on else 0.4), 3.0)
		var tex: Texture2D = b["icon"]
		var weapon: bool = b["action"] == "attack"
		var k: float = (r * (1.35 if weapon else 0.95)) / maxf(tex.get_width(), tex.get_height())
		k = maxf(1.0, floorf(k))
		var sz: Vector2 = tex.get_size() * k
		if weapon:  # Waffe schräg, wie zum Schlag erhoben
			draw_set_transform(c, -0.6, Vector2.ONE)
			draw_texture_rect(tex, Rect2(-sz / 2, sz), false, Color(1, 1, 1, 1.0 if on else 0.8))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			draw_texture_rect(tex, Rect2(c - sz / 2, sz), false, Color(1, 1, 1, 1.0 if on else 0.75))
