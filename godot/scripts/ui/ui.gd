class_name UI
extends RefCounted
## Gemeinsame Bausteine für alle Menüs: Theme, Buttons, Titel, Hintergrund und Sammelkarten.
## Alle Menüs sind für 960x540 gebaut und werden automatisch auf die Bildschirmgröße skaliert.

const YELLOW := Color("#ffcc33")
const DARK := Color("#0b0b0d")
const NAVY := Color("#14172e")
const INK := Color("#2b1a00")

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = 12
	var btn := func(bg: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = Color("#7a4b00")
		s.set_border_width_all(4)
		s.set_content_margin_all(6)
		return s
	_theme.set_stylebox("normal", "Button", btn.call(YELLOW))
	_theme.set_stylebox("hover", "Button", btn.call(Color("#ffe080")))
	_theme.set_stylebox("pressed", "Button", btn.call(Color("#e0a820")))
	var focus: StyleBoxFlat = btn.call(Color("#ffe080"))
	focus.border_color = Color.WHITE
	_theme.set_stylebox("focus", "Button", focus)
	_theme.set_stylebox("disabled", "Button", btn.call(Color("#8a7a50")))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_theme.set_color(c, "Button", INK)
	_theme.set_font_size("font_size", "Button", 14)
	var edit := StyleBoxFlat.new()
	edit.bg_color = Color.WHITE
	edit.border_color = YELLOW
	edit.set_border_width_all(3)
	edit.set_corner_radius_all(8)
	edit.set_content_margin_all(10)
	_theme.set_stylebox("normal", "LineEdit", edit)
	_theme.set_stylebox("focus", "LineEdit", edit)
	_theme.set_color("font_color", "LineEdit", INK)
	_theme.set_color("font_placeholder_color", "LineEdit", Color("#9a9aa8"))
	_theme.set_color("caret_color", "LineEdit", INK)
	_theme.set_font_size("font_size", "LineEdit", 18)
	return _theme


## Bildschirm-Grundgerüst: Control in 960x540 mit Theme.
static func screen(root: Control) -> void:
	root.theme = theme()
	root.size = Vector2(960, 540)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func button(parent: Node, text: String, center: Vector2, cb: Callable, w := 320.0, h := 48.0) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	parent.add_child(b)
	b.size = Vector2(w, h)
	b.position = center - b.size / 2
	return b


static func label(parent: Node, text: String, pos: Vector2, font_size := 12, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_CENTER, width := 900.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	# Größe und Position erst setzen, wenn das Textfeld eingefügt ist (sonst ignoriert Godot die Breite)
	l.size = Vector2(width, 0)
	match align:
		HORIZONTAL_ALIGNMENT_CENTER: l.position = Vector2(pos.x - width / 2, pos.y)
		HORIZONTAL_ALIGNMENT_RIGHT: l.position = Vector2(pos.x - width, pos.y)
		_: l.position = pos
	return l


static func title(parent: Node, text: String, y := 36.0, font_size := 26) -> Label:
	var l := label(parent, text, Vector2(480, y - font_size / 2.0), font_size, YELLOW)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 10)
	return l


static func back_button(parent: Node, target := "menu") -> Button:
	return button(parent, "< Zurück", Vector2(96, 500), func(): Nav.goto(target), 160, 50)


## Abgedunkelter Schul-Hintergrund für Menüs.
static func background(parent: Node, bg := "bg-school", offset := -1.0) -> void:
	var tr := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = Art.tex(bg)
	at.region = Rect2(offset if offset >= 0 else randf_range(0, 320), 0, 320, 135)
	tr.texture = at
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	tr.size = Vector2(960, 405)
	rect(parent, Rect2(0, 405, 960, 135), Color("#6b4426"))
	rect(parent, Rect2(0, 0, 960, 540), Color(0.063, 0.075, 0.169, 0.62))


static func rect(parent: Node, r: Rect2, color: Color, border := 0, border_color := Color.TRANSPARENT) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border_color
	s.set_border_width_all(border)
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	p.position = r.position
	p.size = r.size
	return p


static func image(parent: Node, key: String, center: Vector2, scale := 1.0) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = Art.tex(key)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	tr.size = tr.texture.get_size() * scale
	tr.position = center - tr.size / 2
	return tr


## Bild so skalieren, dass es in max_size passt (Pixel bleiben scharf).
static func fit(parent: Node, key: String, center: Vector2, max_size: Vector2) -> TextureRect:
	var size: Vector2 = Art.tex(key).get_size()
	return image(parent, key, center, minf(max_size.x / size.x, max_size.y / size.y))


## Sammelkarte: Rahmen in Seltenheitsfarbe, Porträt, Name. Gesperrte Karten zeigen eine Silhouette.
static func card(parent: Node, c: Dictionary, unlocked: bool, center: Vector2, k := 1.0) -> Panel:
	var w := 110.0 * k
	var h := 150.0 * k
	var p := rect(parent, Rect2(center - Vector2(w, h) / 2, Vector2(w, h)), Color("#2a2f5a"), int(5 * k), Art.col(Chars.RARITY_COLOR[c["rarity"]]))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	if c["rarity"] == "mythisch":
		var glow := rect(p, Rect2(Vector2(5, 5) * k, Vector2(w, h) - Vector2(10, 10) * k), Color.TRANSPARENT, 2, Color("#ffd84a"))
		var tw := glow.create_tween().set_loops()
		tw.tween_property(glow, "modulate:a", 0.2, 0.7)
		tw.tween_property(glow, "modulate:a", 1.0, 0.7)
	var key: String = "bust-" + c["id"]
	var portrait := fit(p, key, Vector2(w / 2, h * 0.4), Vector2(90, 90) * k)
	if not unlocked:
		portrait.modulate = Color(0.04, 0.04, 0.07)
	var name_label := label(p, c["name"] if unlocked else "???", Vector2(w / 2, h * 0.74), maxi(8, int(9 * k)), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w - 6)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_constant_override("line_spacing", 2)
	name_label.size = Vector2(w - 6, 0)
	return p
