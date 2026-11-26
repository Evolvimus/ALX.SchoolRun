class_name Fx
extends Node2D
## Partikel und schwebende Texte – das „Juice“ des Spiels. Alles wird in einem Knoten gezeichnet.

var _parts: Array[Dictionary] = []
var _leaf: Texture2D


func _ready() -> void:
	z_index = 15
	_leaf = Art.tex("leaf")


## Funken in einer Farbe, z. B. bei Treffern
func burst(pos: Vector2, color: Color, n := 8) -> void:
	for i in n:
		var a := randf() * TAU
		var life := randf_range(0.22, 0.48)
		_parts.append({ "p": pos, "v": Vector2.from_angle(a) * randf_range(60, 210), "g": 600.0,
			"life": life, "max": life, "size": 4.5, "color": color, "shrink": true })


## Staubwölkchen beim Landen, Laufen und Zerschlagen
func dust(pos: Vector2, n := 4) -> void:
	for i in n:
		var life := randf_range(0.25, 0.45)
		_parts.append({ "p": pos, "v": Vector2(randf_range(-55, 55), randf_range(-45, -5)), "g": 0.0,
			"life": life, "max": life, "size": 5.0, "color": Color("#cfcfd6"), "shrink": true, "fade": true })


## Ginkgoblätter, die herumwirbeln (Checkpoint, Ziel)
func leaves(pos: Vector2, n := 6) -> void:
	for i in n:
		var life := randf_range(0.5, 0.9)
		_parts.append({ "p": pos, "v": Vector2.from_angle(deg_to_rad(randf_range(200, 340))) * randf_range(70, 230), "g": 330.0,
			"life": life, "max": life, "tex": _leaf, "rot": randf() * TAU, "spin": randf_range(-3.0, 3.0), "scale": 1.0 })


## Windstreifen eines Laubbläsers
func wind(pos: Vector2, dir: int, length: float) -> void:
	_parts.append({ "p": pos, "v": Vector2(dir * length / 0.52, 0), "g": 0.0, "life": 0.52, "max": 0.52,
		"w": 24.0, "h": 3.0, "color": Color(1, 1, 1, 0.7), "fade": true })


## Kurzer schwebender Text („+5“, „Checkpoint!“)
func text(pos: Vector2, str: String, color := Color("#ffe98a")) -> void:
	var l := Label.new()
	l.text = str
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 16
	get_parent().add_child(l)
	l.size = Vector2(240, 20)
	l.position = pos - Vector2(120, 10)
	var tw := l.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 38, 0.75)
	tw.tween_property(l, "modulate:a", 0.0, 0.75)
	tw.chain().tween_callback(l.queue_free)


func _process(delta: float) -> void:
	for p in _parts:
		p["life"] -= delta
		p["v"].y += p["g"] * delta
		p["p"] += p["v"] * delta
		if p.has("spin"):
			p["rot"] += p["spin"] * delta
	_parts = _parts.filter(func(p): return p["life"] > 0.0)
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		var k: float = p["life"] / p["max"]
		if p.has("tex"):
			var tex: Texture2D = p["tex"]
			var s: float = lerpf(0.2, 1.0, k) * p["scale"]
			draw_set_transform(p["p"], p["rot"], Vector2(s, s))
			draw_texture(tex, -tex.get_size() / 2)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			continue
		var c: Color = p["color"]
		if p.get("fade", false):
			c.a *= k
		if p.has("w"):
			draw_rect(Rect2(p["p"], Vector2(p["w"], p["h"])), c)
		else:
			var size: float = p["size"] * (k if p.get("shrink", false) else 1.0)
			draw_rect(Rect2(p["p"] - Vector2(size, size) / 2, Vector2(size, size)), c)
