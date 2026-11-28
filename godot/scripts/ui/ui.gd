class_name UI
extends RefCounted
## Gemeinsame Bausteine für alle Menüs: Farben, Theme, Buttons, Panels, Kopfleiste, Chips und Sammelkarten.
##
## Alle Menüs sind für eine 960x540-Fläche gebaut. Auf breiteren Bildschirmen (Handys mit 19:9, 20:9 …)
## wird diese Fläche mittig gesetzt; Hintergrund und Kopfleiste reichen bis an die echten Ränder
## (UI.edges() liefert sie, Kerbe/Notch am Handy ist schon abgezogen).

# ------------------------------------------------------------------ Farben
const YELLOW := Color("#ffcc33")
const YELLOW_DARK := Color("#b8860b")
const INK := Color("#2b1a00")
const BG := Color("#0d1024")
const PANEL := Color(0.075, 0.086, 0.18, 0.94)
const PANEL_LIGHT := Color("#1d2246")
const LINE := Color("#2e3566")
const TEXT := Color.WHITE
const MUTED := Color("#8d93b8")
const DIM := Color("#4a5080")
const GREEN := Color("#7ee08a")
const RED := Color("#ff6b8a")
const BLUE := Color("#5ab0ff")
const PURPLE := Color("#b45cff")
# Alte Namen (werden noch im Spiel benutzt)
const DARK := Color("#0b0b0d")
const NAVY := Color("#14172e")

static var _theme: Theme


static func box(bg: Color, radius := 12, border := 0, border_color := Color.TRANSPARENT, margin := 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border)
	s.border_color = border_color
	s.set_content_margin_all(margin)
	s.anti_aliasing = false
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = 10
	# Standard-Button: dunkel mit feinem Rand
	_theme.set_stylebox("normal", "Button", box(PANEL_LIGHT, 12, 2, LINE))
	_theme.set_stylebox("hover", "Button", box(Color("#262c5a"), 12, 2, Color("#4a5394")))
	_theme.set_stylebox("pressed", "Button", box(Color("#151937"), 12, 2, LINE))
	_theme.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), 12, 3, YELLOW))
	_theme.set_stylebox("disabled", "Button", box(Color("#151830"), 12, 2, Color("#232847")))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(c, "Button", TEXT)
	_theme.set_color("font_disabled_color", "Button", DIM)
	_theme.set_font_size("font_size", "Button", 12)
	# Hauptbutton: gelb, mit „Kante“ unten, damit er wie eine Taste wirkt
	_theme.set_type_variation("Primary", "Button")
	var prim := func(bg: Color, edge: int) -> StyleBoxFlat:
		var s := box(bg, 14, 0, YELLOW_DARK)
		s.border_width_bottom = edge
		return s
	_theme.set_stylebox("normal", "Primary", prim.call(YELLOW, 6))
	_theme.set_stylebox("hover", "Primary", prim.call(Color("#ffd95c"), 6))
	_theme.set_stylebox("pressed", "Primary", prim.call(Color("#f0b92a"), 2))
	_theme.set_stylebox("focus", "Primary", box(Color(0, 0, 0, 0), 14, 3, Color.WHITE))
	_theme.set_stylebox("disabled", "Primary", prim.call(Color("#5a5236"), 6))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(c, "Primary", INK)
	_theme.set_color("font_disabled_color", "Primary", Color("#2a2618"))
	_theme.set_font_size("font_size", "Primary", 16)
	# Runde Symbol-Buttons (Zurück, Pause, Ton)
	_theme.set_type_variation("Round", "Button")
	_theme.set_stylebox("normal", "Round", box(Color(1, 1, 1, 0.08), 26, 0))
	_theme.set_stylebox("hover", "Round", box(Color(1, 1, 1, 0.16), 26, 0))
	_theme.set_stylebox("pressed", "Round", box(Color(1, 1, 1, 0.04), 26, 0))
	_theme.set_stylebox("focus", "Round", box(Color(0, 0, 0, 0), 26, 3, YELLOW))
	# Eingabefeld
	var edit := box(Color("#f4f1e6"), 12, 3, YELLOW, 12)
	_theme.set_stylebox("normal", "LineEdit", edit)
	_theme.set_stylebox("focus", "LineEdit", edit)
	_theme.set_color("font_color", "LineEdit", INK)
	_theme.set_color("font_placeholder_color", "LineEdit", Color("#a8a49a"))
	_theme.set_color("caret_color", "LineEdit", INK)
	_theme.set_font_size("font_size", "LineEdit", 20)
	_theme.set_color("font_color", "Label", TEXT)
	return _theme


# ------------------------------------------------------------------ Bildschirmfläche

## Breite der sichtbaren Fläche (mindestens 960, auf Breitbild-Handys mehr)
static func vw() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	return maxf(960.0, tree.root.get_visible_rect().size.x) if tree else 960.0


## Linker und rechter Rand der echten Bildschirmfläche in Menü-Koordinaten (x = links, y = rechts),
## abzüglich Kerbe/Notch.
static func edges() -> Vector2:
	var off := (vw() - 960.0) / 2.0
	var ins := safe_insets()
	return Vector2(-off + ins.x, 960.0 + off - ins.y)


## Kerbe/abgerundete Ecken am Handy (links, rechts) in Spielkoordinaten
static func safe_insets() -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var win := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or safe.size.x <= 0:
		return Vector2.ZERO
	var k := vw() / win.x
	return Vector2(maxf(0, safe.position.x) * k, maxf(0, win.x - safe.end.x) * k)


## Bildschirm-Grundgerüst: 960x540 mittig, mit Theme.
static func screen(root: Control) -> void:
	root.theme = theme()
	root.size = Vector2(960, 540)
	root.position = Vector2((vw() - 960.0) / 2.0, 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Menü-Hintergrund: Schulflur, stark abgedunkelt mit Verlauf, langsam wandernd.
static func background(parent: Node, bg := "bg-school", offset := -1.0) -> void:
	var left := -(vw() - 960.0) / 2.0
	var full := Rect2(left, 0, vw(), 540)
	rect(parent, full, BG)
	var tr := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = Art.tex(bg)
	var start := offset if offset >= 0 else randf_range(0, 120)
	at.region = Rect2(start, 0, vw() / 4.0, 135)
	tr.texture = at
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = Color(1, 1, 1, 0.55)
	parent.add_child(tr)
	tr.position = full.position
	tr.size = full.size
	# ganz langsames Wandern, damit das Menü lebt
	var tw := tr.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(at, "region:position:x", start + 60, 18.0)
	tw.tween_property(at, "region:position:x", start, 18.0)
	gradient(parent, full, [Color(BG, 0.82), Color(BG, 0.68), Color(BG, 0.95)], [0.0, 0.45, 1.0])


static func gradient(parent: Node, r: Rect2, colors: Array, offsets: Array, horizontal := false) -> TextureRect:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offsets)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 64
	gt.height = 64
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0) if horizontal else Vector2(0, 1)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	tr.position = r.position
	tr.size = r.size
	return tr


# ------------------------------------------------------------------ Bausteine

static func button(parent: Node, text: String, center: Vector2, cb: Callable, w := 320.0, h := 56.0, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	parent.add_child(b)
	b.size = Vector2(w, h)
	b.position = center - b.size / 2
	return b


static func primary(parent: Node, text: String, center: Vector2, cb: Callable, w := 320.0, h := 64.0) -> Button:
	return button(parent, text, center, cb, w, h, "Primary")


## Runder Symbol-Button
static func icon_button(parent: Node, icon: String, center: Vector2, cb: Callable, d := 52.0, icon_scale := 3.0) -> Button:
	var b := button(parent, "", center, cb, d, d, "Round")
	var img := image(b, icon, Vector2(d, d) / 2, icon_scale)
	img.name = "Icon"
	return b


## Button mit Symbol oben und kleiner Beschriftung darunter (Kacheln im Hauptmenü)
static func tile(parent: Node, icon: String, text: String, center: Vector2, cb: Callable, w := 84.0, h := 96.0, icon_size := 40.0) -> Button:
	var b := button(parent, "", center, cb, w, h)
	fit(b, icon, Vector2(w / 2, h / 2 - 10), Vector2(icon_size, icon_size))
	label(b, text, Vector2(w / 2, h - 26), 8, MUTED, HORIZONTAL_ALIGNMENT_CENTER, w)
	return b


static func label(parent: Node, text: String, pos: Vector2, font_size := 12, color := TEXT, align := HORIZONTAL_ALIGNMENT_CENTER, width := 900.0) -> Label:
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


## Mehrzeiliger Text mit Umbruch
static func para(parent: Node, text: String, pos: Vector2, width: float, font_size := 9, color := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(parent, text, pos, font_size, color, HORIZONTAL_ALIGNMENT_LEFT, width)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", 7)
	l.size = Vector2(width, 0)
	return l


static func title(parent: Node, text: String, y := 36.0, font_size := 26) -> Label:
	var l := label(parent, text, Vector2(480, y - font_size / 2.0), font_size, YELLOW)
	outline(l, 8)
	return l


static func outline(l: Label, size := 6, color := Color("#05060f")) -> void:
	l.add_theme_color_override("font_outline_color", color)
	l.add_theme_constant_override("outline_size", size)


## Kopfleiste: Zurück-Button links am Bildschirmrand, Titel daneben. Gibt den rechten Rand zurück,
## an dem man Chips anhängen kann.
static func top_bar(parent: Node, text: String, back := "menu", sub := "") -> float:
	var e := edges()
	var x := e.x + 20
	if back != "":
		icon_button(parent, "icon-back", Vector2(x + 26, 40), func(): Nav.goto(back))
		x += 66
	var t := label(parent, text, Vector2(x, 26 if sub != "" else 32), 18, YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 520)
	outline(t, 6)
	if sub != "":
		label(parent, sub, Vector2(x, 52), 8, MUTED, HORIZONTAL_ALIGNMENT_LEFT, 520)
	return e.y - 20


## Abgerundete Info-Pille mit Symbol und Text. right = rechter Rand (für rechtsbündige Reihen).
## Gibt die Pille zurück; ihre Breite ergibt sich aus dem Text.
static func chip(parent: Node, icon: String, text: String, right: float, y := 40.0, color := TEXT, font_size := 10) -> PanelContainer:
	var pc := PanelContainer.new()
	var s := box(Color(0.06, 0.07, 0.15, 0.85), 18, 2, LINE, 0)
	s.content_margin_left = 12
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", s)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(row)
	if icon != "":
		var tr := TextureRect.new()
		tr.texture = Art.tex(icon)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var k := 18.0 / maxf(tr.texture.get_width(), tr.texture.get_height())
		tr.custom_minimum_size = tr.texture.get_size() * maxf(1.0, floorf(k * 2) / 2)
		row.add_child(tr)
	var l := Label.new()
	l.name = "Text"
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	parent.add_child(pc)
	pc.size = pc.get_combined_minimum_size()
	pc.position = Vector2(right - pc.size.x, y - pc.size.y / 2)
	return pc


## Kleine farbige Marke (z. B. Seltenheit, „BOSS“)
static func tag(parent: Node, text: String, pos: Vector2, color: Color, font_size := 8) -> PanelContainer:
	var pc := PanelContainer.new()
	var s := box(Color(color, 0.18), 8, 2, color, 0)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	pc.add_theme_stylebox_override("panel", s)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color.lightened(0.25))
	pc.add_child(l)
	parent.add_child(pc)
	pc.size = pc.get_combined_minimum_size()
	pc.position = pos
	return pc


## Abgerundetes Panel (Karte/Fläche)
static func panel(parent: Node, r: Rect2, accent := Color.TRANSPARENT, bg := PANEL) -> Panel:
	var p := Panel.new()
	var s := box(bg, 16, 2, accent if accent.a > 0 else LINE)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	p.position = r.position
	p.size = r.size
	return p


static func rect(parent: Node, r: Rect2, color: Color, border := 0, border_color := Color.TRANSPARENT, radius := 0) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border_color
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
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


## Lichtschein hinter Figuren
static func glow(parent: Node, center: Vector2, radius: float, color: Color) -> TextureRect:
	var g := image(parent, "glow", center, radius / 32.0)
	g.modulate = color
	g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return g


## Sammelkarte: abgerundet, Leiste in Seltenheitsfarbe, Porträt, Name. Gesperrte Karten zeigen eine Silhouette.
static func card(parent: Node, c: Dictionary, unlocked: bool, center: Vector2, k := 1.0) -> Panel:
	var w := 110.0 * k
	var h := 150.0 * k
	var rc: Color = Art.col(Chars.RARITY_COLOR[c["rarity"]])
	var p := Panel.new()
	var s := box(Color("#1a1f44") if unlocked else Color("#12152e"), int(10 * k), maxi(2, int(3 * k)), rc if unlocked else Color(rc, 0.45))
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(p)
	p.position = center - Vector2(w, h) / 2
	p.size = Vector2(w, h)
	p.clip_contents = true
	var band := rect(p, Rect2(0, 0, w, h * 0.62), Color(rc, 0.22 if unlocked else 0.08))
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if c["rarity"] == "mythisch" and unlocked:
		var shine := rect(p, Rect2(0, 0, w, h), Color.TRANSPARENT, 2, Color("#ffd84a"), int(10 * k))
		var tw := shine.create_tween().set_loops()
		tw.tween_property(shine, "modulate:a", 0.15, 0.8)
		tw.tween_property(shine, "modulate:a", 1.0, 0.8)
	var portrait := fit(p, "bust-" + c["id"], Vector2(w / 2, h * 0.36), Vector2(84, 84) * k)
	if not unlocked:
		portrait.modulate = Color(0.03, 0.035, 0.08)
		image(p, "icon-lock", Vector2(w / 2, h * 0.36), 2.0 * k).modulate = Color(rc, 0.7)
	var name_label := label(p, c["name"] if unlocked else "???", Vector2(w / 2, h * 0.68), maxi(7, int(8 * k)), TEXT if unlocked else DIM, HORIZONTAL_ALIGNMENT_CENTER, w - 8)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_constant_override("line_spacing", 3)
	name_label.size = Vector2(w - 8, 0)
	return p


## Kurzer Einblende-Effekt für Elemente beim Öffnen eines Bildschirms
static func pop_in(node: CanvasItem, delay := 0.0, dy := 14.0) -> void:
	if Nav.args.has("shot") or Nav.args.has("bot"):
		return
	var c := node as Control
	node.modulate.a = 0.0
	var tw := node.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, 0.28).set_delay(delay)
	if c:
		var y := c.position.y
		c.position.y = y + dy
		tw.tween_property(c, "position:y", y, 0.35).set_delay(delay)


## Klick oder Tipp auf ein Control (für Panels, die keine Buttons sind). Tipps kommen am Handy
## als Maus-Klick an (emulate_mouse_from_touch), deshalb reicht die Maus-Abfrage.
static func is_tap(e: InputEvent) -> bool:
	return e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT


static func back_button(parent: Node, target := "menu") -> Button:
	var e := edges()
	return icon_button(parent, "icon-back", Vector2(e.x + 46, 40), func(): Nav.goto(target))
