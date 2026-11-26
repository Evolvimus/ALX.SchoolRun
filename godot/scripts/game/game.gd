class_name Game
extends Node2D
## Ein Level: baut Gelände und Objekte aus der Kachelkarte, steuert Spielfigur, Gegner, Anzeige und Levelende.
##
## Regeln: Man hat je nach Schwierigkeitsstufe 5, 3 oder 1 Leben (grüne Blätter). Ein Setzling füllt sie wieder auf.
## Sind alle weg oder stürzt man ab, ist das ein FEHLVERSUCH: Es geht sofort am letzten Setzling weiter,
## der Zähler läuft mit. Ein „Game Over“ gibt es nicht.

const T := 45.0
const BAR := 72.0
const FULL := "#KRL"
const TILE_TEX := { "K": "box", "R": "shelf", "L": "lab", "H": "ladder", "^": "spikes" }
const DIFFICULTY := {
	"entspannt": { "label": "Entspannt", "lives": 5, "invuln": 2200.0, "door": 7000.0, "reward": 1.0 },
	"normal": { "label": "Normal", "lives": 3, "invuln": 1500.0, "door": 5000.0, "reward": 1.0 },
	"abi": { "label": "Abiprüfung", "lives": 1, "invuln": 1200.0, "door": 4000.0, "reward": 1.5 },
}
const MEDALS := [["leaves", "Alle Blätter"], ["clean", "Ohne Treffer"], ["time", "Zielzeit"]]

var params := {}
## Spielzeit in Millisekunden (läuft nicht während des kurzen Einfrierens bei Treffern)
var now := 0.0
var player: Player
var fx: Fx
var enemies: Array = []
var spikes: Array[Rect2] = []
var mats: Array[Rect2] = []
## Rollwagen und Aufzüge: { body, origin, axis, dist, move, rest }
var movers: Array[Dictionary] = []
var collected := 0
var checkpoint_index := -1
var attempts := 0

var level: Dictionary
var level_index := 0
var grid: PackedStringArray
var width := 0.0
var height := 0.0
var _diff: Dictionary
var _max_lives := 3
var _hits := 0
var _leaves: Array[Dictionary] = []
var _hefte: Array[Dictionary] = []
var _hefte_new := 0
var _checkpoints: Array[Dictionary] = []
var _doors: Array[Dictionary] = []
var _plates: Array[Dictionary] = []
var _crumbles: Array[Dictionary] = []
var _crates: Array[StaticBody2D] = []
var _solids: StaticBody2D
var _spawn := Vector2.ZERO
var _safe_pos := Vector2.ZERO
var _goal := Vector2.ZERO
var _tree_gold: Sprite2D
var _total := 0
var _bonus := 0
var _combo := 0
var _last_leaf_at := -9999.0
var _done := false
var _bot: Bot
var _tutorial: Tutorial
var _freeze := 0
var _shake_until := 0.0
var _shake_amount := 0.0
var _lead := 90.0
var _follow := true
var _toasts: Array[String] = []
var _toast_busy := false
var _panel_x := 480.0
var _up_latched := false
var _floor_line := 405.0

var _cam: Camera2D
var _bg: Sprite2D
var _hud: Control
var _overlay: CanvasLayer
var _flash: ColorRect
var _hud_lives: Array[TextureRect] = []
var _hud_leaves: Label
var _hud_hefte: Label
var _hud_time: Label
var _hud_attempts: Label


# ====================================================================== Aufbau

func _ready() -> void:
	level_index = clampi(int(params.get("level", 0)), 0, Levels.list.size() - 1)
	level = Levels.list[level_index]
	grid = level["map"]
	_total = Levels.count_leaves(level)
	width = grid[0].length() * T
	height = grid.size() * T
	_floor_line = height - 3 * T
	_diff = DIFFICULTY.get(Save.data["difficulty"], DIFFICULTY["normal"])
	_max_lives = _diff["lives"]
	_bot = Bot.new() if Nav.args.has("bot") else null
	var c := Chars.get_char(Save.data["selected"])

	_build_background()
	fx = Fx.new()
	add_child(fx)
	_build_terrain()
	_build_objects()
	_build_hints(c)

	player = Player.new()
	add_child(player)
	player.setup(self, c, _spawn)
	player.lives = _max_lives
	player.invuln_ms = _diff["invuln"]
	_safe_pos = _spawn

	_cam = Camera2D.new()
	_cam.limit_left = 0
	_cam.limit_top = 0
	_cam.limit_right = int(width)
	_cam.limit_bottom = int(height)
	_cam.position = _cam_target()
	add_child(_cam)
	_cam.make_current()

	_overlay = CanvasLayer.new()
	_overlay.layer = 20
	add_child(_overlay)
	_build_hud(c)
	_build_touch()
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.3, 0.3, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_flash)
	_flash.size = Vector2(960, 540)
	if level.has("tutorial"):
		_tutorial = Tutorial.new()
		add_child(_tutorial)
		_tutorial.setup(self, level["tutorial"], _overlay, Nav.touch_enabled(), _weapon_name(c))


func _weapon_name(c: Dictionary) -> String:
	return "LINEAL-HIEB" if c["weapon"] == "ruler" else "HAMMER-SCHLAG"


## Der Hintergrund wiederholt sich waagerecht und alle 9 Kacheln (ein Stockwerk) auch senkrecht.
func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	_bg = Sprite2D.new()
	_bg.texture = Art.tex(level["bg"])
	_bg.centered = false
	_bg.scale = Vector2(3, 3)
	_bg.region_enabled = true
	_bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_bg.region_rect = Rect2(0, 0, 320, 180)
	layer.add_child(_bg)
	# unterhalb des untersten Bodens ist es dunkel (Abgrund)
	var dark := ColorRect.new()
	dark.color = Color("#0b0b0d")
	dark.z_index = -5
	add_child(dark)
	dark.position = Vector2(-1000, _floor_line)
	dark.size = Vector2(width + 2000, 1200)


func _thin_shape(parent: Node, center: Vector2, w: float) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(w, 18)
	shape.shape = r
	shape.position = center
	shape.one_way_collision = true
	parent.add_child(shape)
	return shape


## Zusammenhängende Kacheln einer Zeile werden zu einem Kollisionskörper – das verhindert Hängenbleiben an Kanten.
## Bretter (=) und das obere Ende einer Sprossenwand sind von unten durchspringbar.
func _build_terrain() -> void:
	_solids = StaticBody2D.new()
	_solids.collision_layer = 1
	add_child(_solids)
	for ry in grid.size():
		var row := grid[ry]
		var run := -1
		var thin := -1
		for rx in row.length() + 1:
			var ch := row[rx] if rx < row.length() else " "
			var full := FULL.contains(ch)
			if full and run < 0:
				run = rx
			if not full and run >= 0:
				var shape := CollisionShape2D.new()
				var r := RectangleShape2D.new()
				r.size = Vector2((rx - run) * T, T)
				shape.shape = r
				shape.position = Vector2(run * T + r.size.x / 2, ry * T + T / 2)
				_solids.add_child(shape)
				run = -1
			var is_thin := ch == "=" or (ch == "H" and (ry == 0 or grid[ry - 1][rx] != "H"))
			if is_thin and thin < 0:
				thin = rx
			if not is_thin and thin >= 0:
				var w := (rx - thin) * T
				_thin_shape(_solids, Vector2(thin * T + w / 2, ry * T + 9), w)
				thin = -1
	var view := Node2D.new()
	view.z_index = 5
	view.draw.connect(func():
		for ry in grid.size():
			var row := grid[ry]
			for rx in row.length():
				var ch := row[rx]
				var key := ""
				if ch == "#":
					key = "under" if ry > 0 and grid[ry - 1][rx] == "#" else "ground"
				elif TILE_TEX.has(ch):
					key = TILE_TEX[ch]
				elif ch == "=":
					view.draw_texture_rect(Art.tex("platform"), Rect2(rx * T, ry * T, T, 18), false)
				if key != "":
					view.draw_texture_rect(Art.tex(key), Rect2(rx * T, ry * T, T, T), false))
	add_child(view)


func _static_box(pos: Vector2, size: Vector2, group: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = pos
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	shape.shape = r
	body.add_child(shape)
	if group != "":
		body.add_to_group(group)
	add_child(body)
	return body


func _build_objects() -> void:
	var holes: Array = []
	var burners := 0
	var owned: Array = Save.data["hefte"].get(level["id"], [])
	for ry in grid.size():
		var row := grid[ry]
		for rx in row.length():
			var ch := row[rx]
			var x := rx * T + T / 2
			var y := ry * T + T / 2
			var floor_y := (ry + 1) * T
			match ch:
				"M":
					Enemies.make_standing(self, "mat", Vector2(x, floor_y), 3.0, 5)
					mats.append(Rect2(x - T / 2, floor_y - 15, T, 15))
				"B":
					var crate := _static_box(Vector2(x, y), Vector2(T, T), "crate")
					Enemies.make_sprite(crate, "crate", Vector2.ZERO, 3.0, 5)
					_crates.append(crate)
				"^":
					spikes.append(Rect2(x - 20, floor_y - 14, 40, 14))
				"c":
					add_leaf(Enemies.make_sprite(self, "leaf", Vector2(x, y), 2.0, 6), Vector2(x, y), 1)
				"h":
					var index := _hefte.size()
					var node := Enemies.make_sprite(self, "heft", Vector2(x, y), 3.0, 6)
					var had := index in owned
					if had:
						node.modulate.a = 0.35
					var tw := node.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
					tw.tween_property(node, "position:y", y - 6, 0.8)
					tw.tween_property(node, "position:y", y, 0.8)
					_hefte.append({ "node": node, "pos": Vector2(x, y), "index": index, "taken": false, "had": had })
				"S":
					_checkpoints.append({ "x": x, "floor": floor_y, "active": false,
						"img": Enemies.make_standing(self, "seed-0", Vector2(x, floor_y), 3.0, 6) })
				"F":
					_goal = Vector2(x, floor_y)
					Enemies.make_standing(self, "tree-bare", _goal, 3.0, 4)
					_tree_gold = Enemies.make_standing(self, "tree-gold", _goal, 3.0, 4)
					_tree_gold.modulate.a = 0
				"P":
					_spawn = Vector2(x, floor_y - 42)
				"D":
					var body := _static_box(Vector2(x, floor_y - 90), Vector2(T, 180), "")
					_doors.append({ "body": body, "shape": body.get_child(0), "x": x, "floor": floor_y, "open": false, "close_at": -1.0,
						"img": Enemies.make_standing(self, "door", Vector2(x, floor_y), 3.0, 5) })
				"_":
					_plates.append({ "rect": Rect2(x - 20, floor_y - 14, 40, 14), "x": x, "pressed": false, "door": -1,
						"img": Enemies.make_standing(self, "plate-0", Vector2(x, floor_y), 3.0, 5) })
				"~":
					var body := StaticBody2D.new()
					body.collision_layer = 1
					add_child(body)
					var shape := _thin_shape(body, Vector2(x, ry * T + 9), T)
					var img := Enemies.make_sprite(self, "crumble", Vector2(x, ry * T + 9), 3.0, 5)
					_crumbles.append({ "shape": shape, "img": img, "base": img.position, "state": "idle", "t": 0.0,
						"rect": Rect2(rx * T, ry * T, T, 18) })
				"-", "|":
					var body := AnimatableBody2D.new()
					body.collision_layer = 1
					body.sync_to_physics = true
					# Der Rollwagen liegt bündig im Boden (in einer Lücke), der Aufzug steht auf dem Boden: aufspringen!
					var origin := Vector2(rx * T + T, ry * T + 9) if ch == "-" else Vector2(rx * T + T, floor_y - 9)
					body.position = origin
					add_child(body)
					_thin_shape(body, Vector2.ZERO, 2 * T)
					Enemies.make_sprite(body, "mover", Vector2.ZERO, 3.0, 5)
					movers.append({ "body": body, "origin": origin,
						"axis": Vector2.RIGHT if ch == "-" else Vector2.UP,
						"dist": 5 * T if ch == "-" else 4 * T, "move": 1800.0, "rest": 900.0 if ch == "-" else 1300.0 })
				"m": enemies.append(Enemies.DustMouse.new(self, Vector2(x, y)))
				"e":
					for i in 3:
						enemies.append(Enemies.PaperPlane.new(self, Vector2(x, y), i))
				"w": holes.append({ "pos": Vector2(x, floor_y), "col": rx })
				"o": enemies.append(Enemies.Ball.new(self, Vector2(x, y), _floor_below(rx, ry)))
				"<": enemies.append(Enemies.Blower.new(self, Vector2(x, floor_y), -1))
				">": enemies.append(Enemies.Blower.new(self, Vector2(x, floor_y), 1))
				"N": enemies.append(Enemies.Magnet.new(self, Vector2(x, y)))
				"f":
					enemies.append(Enemies.Burner.new(self, Vector2(x, floor_y), burners * 1100.0))
					burners += 1
				"C": enemies.append(Enemies.Caterpillar.new(self, Vector2(x, floor_y)))
				"T": enemies.append(Enemies.Target.new(self, Vector2(x, floor_y)))
	# Benachbarte Löcher gehören zu einem Bücherwurm
	holes.sort_custom(func(a, b): return a["col"] < b["col"])
	var group: Array = []
	for h in holes:
		if group.size() > 0 and h["col"] - group[-1]["col"] > 14:
			enemies.append(Enemies.Bookworm.new(self, group.map(func(g): return g["pos"])))
			group = []
		group.append(h)
	if group.size() > 0:
		enemies.append(Enemies.Bookworm.new(self, group.map(func(g): return g["pos"])))
	_checkpoints.sort_custom(func(a, b): return a["x"] < b["x"])
	_doors.sort_custom(func(a, b): return a["x"] < b["x"])
	# Jede Druckplatte öffnet die nächste Tür rechts von ihr (auf ähnlicher Höhe)
	for p in _plates:
		for i in _doors.size():
			if _doors[i]["x"] > p["x"] and absf(_doors[i]["floor"] - p["rect"].end.y) < 4 * T:
				p["door"] = i
				break


func _floor_below(col: int, row: int) -> float:
	for r in range(row, grid.size()):
		if FULL.contains(grid[r][col]):
			return r * T
	return height


func _build_hints(c: Dictionary) -> void:
	var touch := Nav.touch_enabled()
	var keys := { "LAUFEN": "< >" if touch else "PFEILTASTEN", "SPRINGEN": "^" if touch else "LEERTASTE",
		"HOCH": "^" if touch else "PFEIL HOCH", "HIEB": "X", "WAFFE": _weapon_name(c) }
	for h in level["hints"]:
		var text: String = h[2]
		for k in keys:
			text = text.replace("{%s}" % k, keys[k])
		var l := Label.new()
		l.text = text
		l.z_index = 3
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_constant_override("line_spacing", 6)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.043, 0.043, 0.051, 0.8)
		bg.content_margin_left = 8
		bg.content_margin_right = 8
		bg.content_margin_top = 6
		bg.content_margin_bottom = 6
		l.add_theme_stylebox_override("normal", bg)
		add_child(l)
		l.position = Vector2(h[0], h[1])


## Ein einsammelbares Blatt (auch von der Raupe gerettete große Blätter).
func add_leaf(node: Sprite2D, pos: Vector2, value: int) -> void:
	var entry := { "node": node, "pos": pos, "value": value, "taken": false, "tweens": [] }
	_leaves.append(entry)
	if value == 1:
		var bob := node.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		var d := 0.9 + fmod(pos.x, 7) * 0.04
		bob.tween_property(node, "position:y", pos.y - 5, d)
		bob.tween_property(node, "position:y", pos.y, d)
		var spin := node.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		var e := 1.3 + fmod(pos.x, 5) * 0.06
		spin.tween_property(node, "rotation_degrees", 9.0, e)
		spin.tween_property(node, "rotation_degrees", -9.0, e)
		entry["tweens"] = [bob, spin]


func _build_hud(c: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_hud = Control.new()
	UI.screen(_hud)
	layer.add_child(_hud)
	UI.rect(_hud, Rect2(0, 0, 960, BAR), Color.BLACK)
	UI.rect(_hud, Rect2(0, BAR, 960, 3), Color("#2c2c31"))
	var portrait := Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("#1c1c22")
	ps.border_color = Color("#6b4426")
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(27)
	portrait.add_theme_stylebox_override("panel", ps)
	portrait.clip_contents = true
	_hud.add_child(portrait)
	portrait.position = Vector2(15, 9)
	portrait.size = Vector2(54, 54)
	UI.fit(portrait, "bust-" + c["id"], Vector2(27, 31), Vector2(46, 46))
	_hud_lives.clear()
	for i in _max_lives:
		_hud_lives.append(UI.image(_hud, "leaf-green", Vector2(96 + i * 36, 26), 1.5))
	_hud_attempts = UI.label(_hud, "", Vector2(80, 50), 8, Color("#9a9aa8"), HORIZONTAL_ALIGNMENT_LEFT, 220)
	UI.image(_hud, "leaf", Vector2(300, 38), 1.6)
	_hud_leaves = UI.label(_hud, "", Vector2(324, 28), 16, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_LEFT, 150)
	if _hefte.size() > 0:
		UI.image(_hud, "heft", Vector2(462, 37), 2.4)
		_hud_hefte = UI.label(_hud, "", Vector2(480, 28), 16, Color("#8fb4ff"), HORIZONTAL_ALIGNMENT_LEFT, 80)
	_hud_time = UI.label(_hud, "", Vector2(560, 28), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 200)
	UI.label(_hud, "%s · %s" % [Levels.label(level_index), level["name"]], Vector2(944, 14), 10, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 300)
	UI.label(_hud, c["name"], Vector2(944, 32), 9, Color("#9a9aa8"), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	UI.label(_hud, _diff["label"], Vector2(944, 48), 8, Color("#ffcc33"), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	_refresh_hud()


func _refresh_hud() -> void:
	for i in _hud_lives.size():
		_hud_lives[i].texture = Art.tex("leaf-green" if i < player.lives else "leaf-wilt")
	if _hud_hefte:
		var have := 0
		for h in _hefte:
			if h["had"] or h["taken"]:
				have += 1
		_hud_hefte.text = "%d/%d" % [have, _hefte.size()]
	_hud_attempts.text = "" if _tutorial or attempts == 0 else "Fehlversuche: %d" % attempts


## Touch-Buttons (Handy/Tablet oder mit --touch)
func _build_touch() -> void:
	if not Nav.touch_enabled():
		return
	for b in [[70, "<", "move_left"], [180, ">", "move_right"], [660, "v", "move_down"], [770, "X", "attack"], [880, "^", "jump"]]:
		var t := TouchScreenButton.new()
		t.texture_normal = Art.tex("touch")
		t.scale = Vector2(3, 3)
		t.position = Vector2(b[0] - 45, 478 - 45)
		t.action = b[2]
		t.passby_press = true
		_hud.get_parent().add_child(t)
		UI.label(_hud, b[1], Vector2(b[0], 468), 20)


# ====================================================================== Hilfen für Gegner, Tutorial und Bot

func _cell(x: float, y: float) -> String:
	var row := int(floor(y / T))
	var col := int(floor(x / T))
	if row < 0 or row >= grid.size() or col < 0 or col >= grid[0].length():
		return " "
	return grid[row][col]


func solid_at(x: float, y: float) -> bool:
	var ch := _cell(x, y)
	if FULL.contains(ch):
		return true
	if fmod(y, T) >= 20:
		return false
	return ch == "=" or ch == "~" or (ch == "H" and _cell(x, y - T) != "H")


func ladder_at(pos: Vector2) -> bool:
	return _cell(pos.x, pos.y) == "H"


func crate_at(x: float, y: float) -> bool:
	for c in _crates:
		if is_instance_valid(c) and absf(c.position.x - x) < 23 and absf(c.position.y - y) < 23:
			return true
	return false


func door_at(x: float, y: float) -> bool:
	for d in _doors:
		if not d["open"] and absf(d["x"] - x) < 23 and y < d["floor"] and y > d["floor"] - 180:
			return true
	return false


func on_screen(x: float, margin := 100.0) -> bool:
	return absf(x - _cam.get_screen_center_position().x) < 480 + margin


func view_rect() -> Rect2:
	return Rect2(_cam.get_screen_center_position() - Vector2(480, 270), Vector2(960, 540))


func enemy_defeated(e, at_pos: Vector2) -> void:
	_bonus += e.reward
	fx.text(at_pos - Vector2(0, 10), "+%d" % e.reward)
	if _tutorial:
		_tutorial.defeated[e.kind] = true
	if e.kind != "":
		Save.data["defeated"][e.kind] = int(Save.data["defeated"].get(e.kind, 0)) + 1
		Save.persist()
	Sfx.play("defeat")
	_freeze = 4  # kurzes Einfrieren macht Treffer spürbar


## Karton zertrümmern (Herr Hammer)
func break_crate(body: Node) -> void:
	if not is_instance_valid(body) or body.is_queued_for_deletion() or not body in _crates:
		return
	_crates.erase(body)
	var pos: Vector2 = body.position
	fx.burst(pos, Color("#b8834c"), 14)
	fx.burst(pos, Color("#d9c7a0"), 6)
	shake(90, 0.006)
	Sfx.play("bonk")
	if player.char_data["smash_quote"] != "" and not has_meta("smash_quoted"):
		set_meta("smash_quoted", true)
		player.say(player.char_data["smash_quote"], now)
	body.queue_free()
	var bits := Enemies.make_sprite(self, "crate", pos, 3.0, 5)
	var tw := bits.create_tween().set_parallel()
	tw.tween_property(bits, "scale", Vector2(4.2, 4.2), 0.16)
	tw.tween_property(bits, "rotation", 0.2, 0.16)
	tw.tween_property(bits, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(bits.queue_free)


## Tür öffnen. ms > 0: sie schließt sich nach dieser Zeit wieder; sonst bleibt sie offen.
func open_door(i: int, ms := -1.0) -> void:
	var d: Dictionary = _doors[i]
	d["close_at"] = now + ms if ms > 0 else -1.0
	if d["open"]:
		return
	d["open"] = true
	(d["shape"] as CollisionShape2D).set_deferred("disabled", true)
	var img: Sprite2D = d["img"]
	img.texture = Art.tex("door-open")
	fx.dust(Vector2(d["x"], d["floor"] - 20), 8)
	img.create_tween().tween_property(img, "position:y", d["floor"] - 172.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


## Für das Tutorial: die nächste noch geschlossene Tür dauerhaft öffnen
func open_next_door() -> void:
	for i in _doors.size():
		if not _doors[i]["open"]:
			open_door(i)
			return


## Rollwagen/Aufzug: [Anteil der Strecke 0..1, verbleibende Haltezeit am Start in ms (0 = unterwegs)]
## Ablauf: am Start halten – hinfahren – am Ende halten – zurückfahren.
func mover_phase(m: Dictionary) -> Array:
	var mv: float = m["move"]
	var rest: float = m["rest"]
	var u := fmod(now, 2 * (mv + rest))
	if u < rest:
		return [0.0, rest - u]
	u -= rest
	if u < mv:
		return [smoothstep(0.0, 1.0, u / mv), 0.0]
	u -= mv
	if u < rest:
		return [1.0, 0.0]
	return [1.0 - smoothstep(0.0, 1.0, (u - rest) / mv), 0.0]


func shake(ms: float, intensity: float) -> void:
	_shake_amount = maxf(_shake_amount if now < _shake_until else 0.0, intensity * 960)
	_shake_until = maxf(_shake_until, now + ms)


func flash_screen(color: Color) -> void:
	_flash.color = color
	_flash.create_tween().tween_property(_flash, "color:a", 0.0, 0.25)


func _standing_on(r: Rect2) -> bool:
	var pr := player.rect()
	return player.is_on_floor() and absf(pr.end.y - r.position.y) < 5 and pr.end.x > r.position.x + 2 and pr.position.x < r.end.x - 2


# ====================================================================== Spielschleife

func _controls() -> Dictionary:
	if _done:
		return { "left": false, "right": false, "jump": false, "attack": false, "up": false, "down": false }
	if _bot:
		return _bot.controls(self, now)
	# Pfeil hoch (und am Handy der Sprung-Button) klettert an der Sprossenwand und springt sonst
	var near_ladder := player.climbing or ladder_at(player.position) or ladder_at(Vector2(player.position.x, player.bottom() - 4))
	var up_key := Input.is_action_pressed("move_up")
	var jump_key := Input.is_action_pressed("jump")
	var touch := Nav.touch_enabled()
	var left := Input.is_action_pressed("move_left")
	var right := Input.is_action_pressed("move_right")
	var climb_key := up_key or (touch and jump_key)
	if climb_key and near_ladder:
		_up_latched = true
	if not climb_key:
		_up_latched = false
	var jump := jump_key or (up_key and not _up_latched)
	if touch:  # am Handy ist der Sprung-Button an der Sprossenwand „hoch“; mit Richtung springt man ab
		jump = jump_key and (not _up_latched or (player.climbing and left != right))
	return {
		"left": left, "right": right, "jump": jump,
		"attack": Input.is_action_pressed("attack"),
		"up": _up_latched, "down": Input.is_action_pressed("move_down"),
	}


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back") and not _done:
		Nav.goto("levels")
	elif event.is_action_pressed("mute"):
		Sfx.toggle_mute()


func _physics_process(delta: float) -> void:
	if _freeze > 0:
		_freeze -= 1
		return
	now += delta * 1000.0
	var c := _controls()
	player.wind_target = 0
	player.force = Vector2.ZERO
	for m in movers:
		(m["body"] as AnimatableBody2D).position = m["origin"] + m["axis"] * m["dist"] * mover_phase(m)[0]
	for e in enemies:
		if e.alive:
			e.tick(now, delta)
	_update_doors()
	if _done:
		player.stop()
		return
	player.tick(now, delta, c)
	_lead = lerpf(_lead, player.facing * 90.0, 0.04)
	_check_leaves()
	_check_checkpoints()
	_update_crumbles()
	_update_plates()
	_discover_enemies()
	if _tutorial:
		_tutorial.tick(now)
	_check_enemies(c)
	var pr := player.rect()
	# Turnmatte: wer drauftritt oder drauffällt, wird hochgeschleudert
	if player.velocity.y >= 0:
		for m in mats:
			if pr.end.x > m.position.x + 6 and pr.position.x < m.end.x - 6 and absf(pr.end.y - m.end.y) < 12:
				player.bounce(-880)
				break
	for s in spikes:
		if s.intersects(pr):
			_hurt(player.position.x + player.facing * 10)
			break
	if player.is_on_floor() and player.floor_node == _solids:
		_safe_pos = player.position
	if player.position.y > height + 60:
		_fail(true)
	if player.position.x > _goal.x - 60 and absf(player.bottom() - _goal.y) < 30 and player.on_ground() and not _done:
		_finish()
	_hud_leaves.text = "%d/%d" % [collected, _total]
	_hud_time.text = "ZEIT %.1f" % (now / 1000.0)


func _cam_target() -> Vector2:
	return Vector2(player.position.x + _lead, player.position.y - 30)


func _process(_delta: float) -> void:
	if _follow:
		var target := _cam_target()
		_cam.position = Vector2(lerpf(_cam.position.x, target.x, 0.14), lerpf(_cam.position.y, target.y, 0.1))
	_cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount if now < _shake_until else Vector2.ZERO
	var corner := _cam.get_screen_center_position() - Vector2(480, 270)
	_bg.region_rect = Rect2(corner.x * 0.5 / 3.0, (corner.y - (_floor_line - 405)) / 3.0, 320, 180)
	if _bot:
		_report_state()


func _check_leaves() -> void:
	for l in _leaves:
		var pos: Vector2 = l["pos"]
		if l["taken"] or absf(pos.x - player.position.x) > 30 or absf(pos.y - player.position.y) > 52:
			continue
		l["taken"] = true
		collected += l["value"]
		_combo = _combo + 1 if now - _last_leaf_at < 700 else 0
		_last_leaf_at = now
		Sfx.leaf(_combo)
		fx.burst(pos, Color("#ffe98a"), 14 if l["value"] > 1 else 5)
		if l["value"] > 1:
			fx.text(pos - Vector2(0, 20), "+%d" % l["value"])
		for tw in l["tweens"]:
			(tw as Tween).kill()
		_fly_away(l["node"])
	for h in _hefte:
		var pos: Vector2 = h["pos"]
		if h["taken"] or absf(pos.x - player.position.x) > 32 or absf(pos.y - player.position.y) > 54:
			continue
		h["taken"] = true
		Sfx.play("magic")
		fx.burst(pos, Color("#8fb4ff"), 16)
		if h["had"]:
			fx.text(pos - Vector2(0, 24), "Schon gefunden", Color("#8fb4ff"))
		else:
			_hefte_new += 1
			fx.text(pos - Vector2(0, 24), "Geheimheft!", Color("#8fb4ff"))
			var owned: Array = Save.data["hefte"].get(level["id"], [])
			owned.append(h["index"])
			Save.data["hefte"][level["id"]] = owned
			Save.persist()
		_fly_away(h["node"])
		_refresh_hud()


func _fly_away(node: Sprite2D) -> void:
	var fly := node.create_tween().set_parallel()
	fly.tween_property(node, "position:y", node.position.y - 34, 0.26)
	fly.tween_property(node, "scale", node.scale * 0.2, 0.26)
	fly.tween_property(node, "modulate:a", 0.0, 0.26)
	fly.tween_property(node, "rotation", 3.5, 0.26)
	fly.chain().tween_callback(node.queue_free)


func _check_checkpoints() -> void:
	for i in _checkpoints.size():
		var cp: Dictionary = _checkpoints[i]
		if cp["active"] or absf(cp["x"] - player.position.x) > 32 or absf(cp["floor"] - 40 - player.position.y) > 70:
			continue
		cp["active"] = true
		checkpoint_index = i
		_spawn = Vector2(cp["x"], cp["floor"] - 42)
		player.lives = _max_lives  # Setzling füllt die Leben wieder auf
		_refresh_hud()
		var img: Sprite2D = cp["img"]
		img.texture = Art.tex("seed-1")
		img.scale = Vector2(1.8, 4.5)
		img.create_tween().tween_property(img, "scale", Vector2(3, 3), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		fx.leaves(Vector2(cp["x"], cp["floor"] - 40), 8)
		fx.text(Vector2(cp["x"], cp["floor"] - 110), "Checkpoint!", Color("#a6e07a"))
		Sfx.play("checkpoint")


## Bröckelbretter: wackeln kurz, fallen dann und wachsen nach ein paar Sekunden nach
func _update_crumbles() -> void:
	for cr in _crumbles:
		var img: Sprite2D = cr["img"]
		match cr["state"]:
			"idle":
				if _standing_on(cr["rect"]):
					cr["state"] = "shake"
					cr["t"] = now + 450
					Sfx.play("crunch")
			"shake":
				img.position.x = cr["base"].x + sin(now / 14.0) * 2
				if now > cr["t"]:
					cr["state"] = "gone"
					cr["t"] = now + 3000
					(cr["shape"] as CollisionShape2D).set_deferred("disabled", true)
					fx.dust(cr["base"], 5)
					var tw := img.create_tween().set_parallel()
					tw.tween_property(img, "position:y", cr["base"].y + 130, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.tween_property(img, "modulate:a", 0.0, 0.4)
			"gone":
				if now > cr["t"] and not (cr["rect"] as Rect2).grow(8).intersects(player.rect()):
					_restore_crumble(cr)


func _restore_crumble(cr: Dictionary) -> void:
	var img: Sprite2D = cr["img"]
	cr["state"] = "idle"
	(cr["shape"] as CollisionShape2D).set_deferred("disabled", false)
	img.position = cr["base"]
	img.modulate.a = 0.0
	img.create_tween().tween_property(img, "modulate:a", 1.0, 0.25)


## Druckplatten halten ihre Tür offen; nach dem Runtergehen bleibt sie noch ein paar Sekunden auf
func _update_plates() -> void:
	var pr := player.rect()
	for p in _plates:
		var pressed: bool = (p["rect"] as Rect2).intersects(pr)
		if pressed != p["pressed"]:
			p["pressed"] = pressed
			(p["img"] as Sprite2D).texture = Art.tex("plate-1" if pressed else "plate-0")
			if pressed:
				Sfx.play("click")
		if pressed and p["door"] >= 0:
			open_door(p["door"], _diff["door"])


func _update_doors() -> void:
	for d in _doors:
		if not d["open"] or d["close_at"] < 0:
			continue
		var img: Sprite2D = d["img"]
		var left: float = d["close_at"] - now
		img.modulate = Color(1, 0.55, 0.55) if left < 1500 and int(now / 120) % 2 else Color.WHITE
		var door_rect := Rect2(d["x"] - 26, d["floor"] - 180, 52, 180)
		if left <= 0 and not door_rect.intersects(player.rect()):
			d["open"] = false
			d["close_at"] = -1.0
			(d["shape"] as CollisionShape2D).set_deferred("disabled", false)
			img.texture = Art.tex("door")
			img.modulate = Color.WHITE
			img.create_tween().tween_property(img, "position:y", d["floor"], 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if on_screen(d["x"]):
				Sfx.play("land")


## Gegner, die zum ersten Mal ins Bild kommen, landen im Lexikon.
func _discover_enemies() -> void:
	var view := view_rect()
	for e in enemies:
		if e.seen or e.kind == "":
			continue
		var at = e.visible_at()
		if at == null or not view.has_point(at):
			continue
		e.seen = true
		if e.kind in Save.data["seen"]:
			continue
		Save.data["seen"].append(e.kind)
		Save.persist()
		_toasts.append(e.kind)
		_next_toast()


func _next_toast() -> void:
	if _toast_busy or _done or _toasts.is_empty():
		return
	var info := Bestiary.find(_toasts.pop_front())
	if info.is_empty():
		return
	_toast_busy = true
	var y := 196.0 if _tutorial and _tutorial.y < 300 else 112.0
	var box := UI.rect(_overlay, Rect2(960 + 20, y - 29, 330, 58), Color(0.043, 0.043, 0.051, 0.92), 3, Color("#5ab0ff"))
	box.theme = UI.theme()
	UI.fit(box, info["icon"], Vector2(36, 29), Vector2(44, 40))
	UI.label(box, "NEU IM LEXIKON", Vector2(70, 14), 9, Color("#5ab0ff"), HORIZONTAL_ALIGNMENT_LEFT, 250)
	UI.label(box, info["name"], Vector2(70, 30), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 250)
	Sfx.play("checkpoint")
	var tw := box.create_tween()
	tw.tween_property(box, "position:x", 940 - 330, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.4)
	tw.tween_property(box, "position:x", 960 + 20, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		box.queue_free()
		_toast_busy = false
		_next_toast())


func _check_enemies(c: Dictionary) -> void:
	var pr := player.rect()
	var atk := player.attack_rect(now)
	var heavy := player.heavy()
	if atk.has_area() and heavy:
		for crate in _crates.duplicate():
			if atk.intersects(Rect2(crate.position - Vector2(22, 22), Vector2(44, 44))):
				break_crate(crate)
	for e in enemies:
		if not e.alive:
			continue
		var hb: Rect2 = e.hitbox()
		if not hb.has_area():
			continue
		if atk.has_area() and e.hittable and e.last_swing != player.swing_id and atk.intersects(hb):
			e.last_swing = player.swing_id
			fx.burst(hb.get_center(), Color.WHITE, 6)
			if heavy:
				shake(110, 0.008)
				Sfx.play("bonk")
			else:
				shake(70, 0.004)
			e.hit(player.facing, 2 if heavy else 1)
			continue
		if not pr.intersects(hb):
			continue
		var from_above := player.velocity.y > 80 and pr.end.y - hb.position.y < 26
		if from_above and e.bouncy:
			player.bounce(-760)
		elif from_above and e.stompable:
			e.stomp()
			player.bounce(-620.0 if c["jump"] else -430.0)
		elif e.harmful:
			_hurt(hb.get_center().x)


func _hurt(from_x: float) -> void:
	if _done or not player.hurt(now, from_x):
		return
	flash_screen(Color(1, 0.3, 0.3, 0.45))
	Sfx.play("hurt")
	if _tutorial:  # im Tutorial verliert man keine Leben
		player.lives = _max_lives
		return
	_hits += 1
	fx.burst(player.position, Color("#ff5a5a"), 10)
	shake(180, 0.012)
	if player.lives >= 0 and player.lives < _hud_lives.size():
		var lost := _hud_lives[player.lives]
		lost.pivot_offset = lost.size / 2
		var tw := lost.create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(lost, "rotation_degrees", 35.0, 0.15)
		tw.tween_property(lost, "rotation_degrees", 0.0, 0.15)
	_refresh_hud()
	if player.lives <= 0:
		_fail(false)


## Fehlversuch: alle Leben weg oder abgestürzt. Es geht sofort am letzten Setzling weiter.
## In der Stufe „Entspannt“ landet man nach einem Sturz auf dem letzten sicheren Boden.
func _fail(fell: bool) -> void:
	if _done:
		return
	Sfx.play("hurt")
	flash_screen(Color(1, 0.3, 0.3, 0.6))
	if not _tutorial:
		attempts += 1
		if fell:
			_hits += 1
	var near: bool = fell and Save.data["difficulty"] == "entspannt"
	player.respawn(now, _safe_pos - Vector2(0, 4) if near else _spawn)
	player.lives = _max_lives
	for cr in _crumbles:
		if cr["state"] != "idle":
			_restore_crumble(cr)
	_freeze = 10
	if not _tutorial:
		fx.text(player.position - Vector2(0, 70), "Fehlversuch %d" % attempts, Color("#ff8a8a"))
	_refresh_hud()
	if _bot and attempts >= 12:
		_done = true
		_report("over")


# ====================================================================== Levelende

func _panel(title_text: String, body: String) -> Control:
	var root := Control.new()
	UI.screen(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(root)
	UI.rect(root, Rect2(_panel_x - 270, 104, 540, 376), Color(0.043, 0.043, 0.051, 0.95), 4, UI.YELLOW)
	UI.label(root, title_text, Vector2(_panel_x, 126), 22, UI.YELLOW)
	var l := UI.label(root, body, Vector2(_panel_x, 176), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 500)
	l.add_theme_constant_override("line_spacing", 10)
	return root


## Ziel erreicht: Die gesammelten Blätter fliegen in die Krone und der Ginkgo wird golden.
func _finish() -> void:
	_done = true
	if _tutorial:
		_tutorial.hide_box()
	var seconds := now / 1000.0
	_follow = false
	var pan := _cam.create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	pan.tween_property(_cam, "position:x", _goal.x - 230, 0.5)
	pan.tween_property(_cam, "position:y", _goal.y - 135, 0.5)
	_panel_x = 310
	var n := mini(collected, 36)
	var share := float(collected) / _total if _total > 0 else 0.0
	var tw := create_tween()
	for i in n:
		tw.tween_interval(0.5 if i == 0 else 0.045)
		tw.tween_callback(_fly_leaf.bind(i, n, share))
	tw.tween_interval(0.65 + 0.62)
	tw.tween_callback(_show_result.bind(seconds))


func _fly_leaf(i: int, n: int, share: float) -> void:
	var start := view_rect().position + Vector2(300, 38)
	var leaf := Enemies.make_sprite(self, "leaf", start, 1.2, 18)
	var target := Vector2(_goal.x - 66 + randf() * 132, _goal.y - 234 + 12 + randf() * 84)
	var tw := leaf.create_tween().set_parallel()
	tw.tween_property(leaf, "position:x", target.x, 0.62).set_trans(Tween.TRANS_SINE)
	tw.tween_property(leaf, "position:y", target.y, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(leaf, "rotation", TAU, 0.62)
	tw.chain().tween_callback(func():
		Sfx.leaf(i % 14)
		_tree_gold.modulate.a = minf(1.0, (i + 1.0) / n * share * 1.15)
		fx.burst(target, Color("#ffe98a"), 2)
		leaf.queue_free())


func _show_result(seconds: float) -> void:
	var id: String = level["id"]
	var par: float = level["par"]
	var earned := {
		"leaves": collected >= _total,
		"clean": _hits == 0 and attempts == 0,
		"time": seconds <= par,
	}
	if earned["leaves"]:
		fx.leaves(_goal - Vector2(0, 175), 30)
	Sfx.play("win")
	# Medaillen: einmal verdient, für immer behalten; jede neue bringt Bonus-Taler
	var medals: Dictionary = Save.data["medals"].get(id, {})
	var new_medals := 0
	for m in MEDALS:
		if earned[m[0]] and not medals.get(m[0], false):
			medals[m[0]] = true
			new_medals += 1
	Save.data["medals"][id] = medals
	var reward := int((collected + _bonus + player.lives * 5 + _hefte_new * 10 + new_medals * 25) * float(_diff["reward"]))
	var best = Save.data["best_times"].get(id)
	var new_best: bool = best == null or seconds < best
	if new_best:
		Save.data["best_times"][id] = seconds
	Save.data["best_leaves"][id] = maxi(int(Save.data["best_leaves"].get(id, 0)), collected)
	Save.data["progress"] = maxi(int(Save.data["progress"]), maxi(1, mini(level_index + 1, Levels.list.size() - 1)))
	Save.data["coins"] = int(Save.data["coins"]) + reward
	Save.persist()

	var lines := ["Blätter: %d/%d" % [collected, _total]]
	if _hefte.size() > 0:
		var have := 0
		for h in _hefte:
			if h["had"] or h["taken"]:
				have += 1
		lines.append("Geheimhefte: %d/%d" % [have, _hefte.size()])
	lines.append("Zeit: %.1fs%s  (Ziel: %ds)" % [seconds, " BESTZEIT!" if new_best else "", int(par)])
	if not _tutorial:
		lines.append("Fehlversuche: %d" % attempts)
	lines.append("+%d Ginkgo-Taler" % reward)
	var root := _panel("Der Ginkgo leuchtet!" if earned["leaves"] else "Geschafft!", "\n".join(lines))
	for i in MEDALS.size():
		var key: String = MEDALS[i][0]
		var mx := _panel_x + (i - 1) * 150.0
		var icon := UI.image(root, "medal-" + key, Vector2(mx, 322), 3.0)
		var has: bool = medals.get(key, false)
		if not has:
			icon.modulate = Color(0.25, 0.25, 0.3)
		elif earned[key]:
			icon.pivot_offset = icon.size / 2
			icon.scale = Vector2(0.2, 0.2)
			icon.create_tween().tween_property(icon, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2 + i * 0.25)
		UI.label(root, MEDALS[i][1], Vector2(mx, 344), 8, Color.WHITE if has else Color("#666c88"), HORIZONTAL_ALIGNMENT_CENTER, 150)
	var has_next := level_index + 1 < Levels.list.size()
	var first := UI.button(root, "Weiter" if has_next else "Nochmal", Vector2(_panel_x - 125, 430),
		func(): Nav.goto("game", { "level": level_index + 1 if has_next else level_index }), 220, 50)
	UI.button(root, "Level", Vector2(_panel_x + 125, 430), func(): Nav.goto("levels"), 220, 50)
	first.grab_focus.call_deferred()
	_report("win")


# ====================================================================== Testausgabe

func _report(result: String) -> void:
	if not (_bot or Nav.args.has("quit")):
		return
	print("BOT_RESULT level=%d id=%s result=%s lives=%d leaves=%d/%d time=%.1f attempts=%d" % [
		level_index, level["id"], result, player.lives, collected, _total, now / 1000.0, attempts])
	if Nav.args.has("quit"):
		get_tree().create_timer(0.3).timeout.connect(get_tree().quit)


func _report_state() -> void:
	if Engine.get_process_frames() % 60 == 0:
		print("BOT_STATE t=%.0f x=%.0f y=%.0f lives=%d attempts=%d" % [now / 1000.0, player.position.x, player.position.y, player.lives, attempts])
