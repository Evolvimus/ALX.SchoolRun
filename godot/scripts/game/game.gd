class_name Game
extends Node2D
## Ein Level: baut Gelände und Objekte aus der Textkarte, steuert Spielfigur, Gegner, Anzeige und Levelende.

const T := 45.0
const BAR := 72.0
const FULL := "#KRL"
const TILE_TEX := { "K": "box", "R": "shelf", "L": "lab" }

static var bot_retries := 0

var params := {}
## Spielzeit in Millisekunden (läuft nicht während des kurzen Einfrierens bei Treffern)
var now := 0.0
var player: Player
var fx: Fx
var enemies: Array = []
var spikes: Array[Rect2] = []
var mats: Array[Rect2] = []
var collected := 0
var checkpoint_index := -1

var level: Dictionary
var level_index := 0
var grid: PackedStringArray
var width := 0.0
var height := 0.0
var _start_checkpoint := -1
var _leaves: Array[Dictionary] = []
var _checkpoints: Array[Dictionary] = []
var _doors: Array[Dictionary] = []
var _crates: Array[StaticBody2D] = []
var _spawn := Vector2.ZERO
var _goal_x := 0.0
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
var _start_time := 0.0

var _cam: Camera2D
var _bg: Sprite2D
var _hud: Control
var _overlay: CanvasLayer
var _flash: ColorRect
var _hud_lives: Array[TextureRect] = []
var _hud_leaves: Label
var _hud_time: Label


# ====================================================================== Aufbau

func _ready() -> void:
	level_index = clampi(int(params.get("level", 0)), 0, Levels.list.size() - 1)
	_start_checkpoint = int(params.get("checkpoint", -1))
	level = Levels.list[level_index]
	grid = level["map"]
	_total = Levels.count_leaves(level)
	width = grid[0].length() * T
	height = grid.size() * T
	_bot = Bot.new() if Nav.args.has("bot") else null
	var c := Chars.get_char(Save.data["selected"])

	_build_background()
	fx = Fx.new()
	add_child(fx)
	_build_terrain()
	_build_objects()
	_build_hints(c)

	# Start am Anfang oder (nach „Nachsitzen“) am letzten Setzling
	if _start_checkpoint >= 0 and _start_checkpoint < _checkpoints.size():
		for i in _start_checkpoint + 1:
			_checkpoints[i]["active"] = true
			(_checkpoints[i]["img"] as Sprite2D).texture = Art.tex("seed-1")
		var cp: Dictionary = _checkpoints[_start_checkpoint]
		_spawn = Vector2(cp["x"], cp["floor"] - 42)
		checkpoint_index = _start_checkpoint
	player = Player.new()
	add_child(player)
	player.setup(self, c, _spawn)

	_cam = Camera2D.new()
	_cam.limit_left = 0
	_cam.limit_top = 0
	_cam.limit_right = int(width)
	_cam.limit_bottom = int(height)
	_cam.position = Vector2(player.position.x + _lead, height / 2)
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
		_tutorial.setup(self, level["tutorial"], _doors, _overlay, Nav.touch_enabled(), _weapon_name(c))


func _weapon_name(c: Dictionary) -> String:
	return "LINEAL-HIEB" if c["weapon"] == "ruler" else "HAMMER-SCHLAG"


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
	_bg.region_rect = Rect2(0, 0, 320, 135)
	layer.add_child(_bg)


## Zusammenhängende Kacheln einer Zeile werden zu einem Kollisionskörper – das verhindert Hängenbleiben an Kanten.
## Bretter (=) sind von unten durchspringbar.
func _build_terrain() -> void:
	var solids := StaticBody2D.new()
	solids.collision_layer = 1
	add_child(solids)
	var add_run := func(c0: int, c1: int, row: int, thin: bool) -> void:
		var shape := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		var w := (c1 - c0 + 1) * T
		r.size = Vector2(w, 18 if thin else T)
		shape.shape = r
		shape.position = Vector2(c0 * T + w / 2, row * T + (9 if thin else T / 2))
		shape.one_way_collision = thin
		solids.add_child(shape)
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
				add_run.call(run, rx - 1, ry, false)
				run = -1
			if ch == "=" and thin < 0:
				thin = rx
			if ch != "=" and thin >= 0:
				add_run.call(thin, rx - 1, ry, true)
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
				elif ch == "^":
					key = "spikes"
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
				"S":
					_checkpoints.append({ "x": x, "floor": floor_y, "active": false,
						"img": Enemies.make_standing(self, "seed-0", Vector2(x, floor_y), 3.0, 6) })
				"F":
					_goal_x = x
					Enemies.make_standing(self, "tree-bare", Vector2(x, floor_y), 3.0, 4)
					_tree_gold = Enemies.make_standing(self, "tree-gold", Vector2(x, floor_y), 3.0, 4)
					_tree_gold.modulate.a = 0
				"P":
					_spawn = Vector2(x, floor_y - 42)
				"D":
					var body := _static_box(Vector2(x, floor_y - 90), Vector2(T, 180), "")
					_doors.append({ "body": body, "img": Enemies.make_standing(self, "door", Vector2(x, floor_y), 3.0, 5), "open": false })
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


func _floor_below(col: int, row: int) -> float:
	for r in range(row, grid.size()):
		if FULL.contains(grid[r][col]):
			return r * T
	return height


func _build_hints(c: Dictionary) -> void:
	var touch := Nav.touch_enabled()
	var keys := { "LAUFEN": "< >" if touch else "PFEILTASTEN", "SPRINGEN": "^" if touch else "LEERTASTE", "HIEB": "X", "WAFFE": _weapon_name(c) }
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
		l.position = Vector2(h[0] * T, h[1] * T)


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
	for i in 3:
		_hud_lives.append(UI.image(_hud, "leaf-green", Vector2(100 + i * 46, 38), 1.9))
	UI.image(_hud, "leaf", Vector2(252, 38), 1.6)
	_hud_leaves = UI.label(_hud, "", Vector2(278, 28), 16, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_LEFT, 200)
	_hud_time = UI.label(_hud, "", Vector2(450, 28), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 240)
	UI.label(_hud, "%s · %s" % [Levels.label(level_index), level["name"]], Vector2(944, 20), 11, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 400)
	UI.label(_hud, c["name"], Vector2(944, 42), 10, Color("#9a9aa8"), HORIZONTAL_ALIGNMENT_RIGHT, 400)


## Touch-Buttons (Handy/Tablet oder mit --touch)
func _build_touch() -> void:
	if not Nav.touch_enabled():
		return
	for b in [[70, "<", "move_left"], [180, ">", "move_right"], [770, "X", "attack"], [880, "^", "jump"]]:
		var t := TouchScreenButton.new()
		t.texture_normal = Art.tex("touch")
		t.scale = Vector2(3, 3)
		t.position = Vector2(b[0] - 45, 478 - 45)
		t.action = b[2]
		t.passby_press = true
		_hud.get_parent().add_child(t)
		UI.label(_hud, b[1], Vector2(b[0], 468), 20)


# ====================================================================== Hilfen für Gegner, Tutorial und Bot

func solid_at(x: float, y: float) -> bool:
	var row := int(floor(y / T))
	var col := int(floor(x / T))
	if row < 0 or row >= grid.size() or col < 0 or col >= grid[0].length():
		return false
	var ch := grid[row][col]
	return FULL.contains(ch) or (ch == "=" and fmod(y, T) < 20)


func crate_at(x: float, y: float) -> bool:
	for c in _crates:
		if is_instance_valid(c) and absf(c.position.x - x) < 23 and absf(c.position.y - y) < 23:
			return true
	return false


func door_at(x: float, y: float) -> bool:
	for d in _doors:
		if not d["open"] and absf(d["body"].position.x - x) < 23 and absf(d["body"].position.y - y) < 90:
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


func shake(ms: float, intensity: float) -> void:
	_shake_until = maxf(_shake_until, now + ms)
	_shake_amount = maxf(_shake_amount if now < _shake_until else 0.0, intensity * 960)


func flash_screen(color: Color) -> void:
	_flash.color = color
	_flash.create_tween().tween_property(_flash, "color:a", 0.0, 0.25)


# ====================================================================== Spielschleife

func _controls() -> Dictionary:
	if _done:
		return { "left": false, "right": false, "jump": false, "attack": false }
	if _bot:
		return _bot.controls(self, now)
	return {
		"left": Input.is_action_pressed("move_left"),
		"right": Input.is_action_pressed("move_right"),
		"jump": Input.is_action_pressed("jump"),
		"attack": Input.is_action_pressed("attack"),
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
	for e in enemies:
		if e.alive:
			e.tick(now, delta)
	if _done:
		player.stop()
		return
	player.tick(now, delta, c)
	_lead = lerpf(_lead, player.facing * 90.0, 0.04)
	_check_leaves()
	_check_checkpoints()
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
	if player.position.y > height + 60:
		_fall()
	if player.position.x > _goal_x - 60 and player.on_ground() and not _done:
		_finish()
	_hud_leaves.text = "%d/%d" % [collected, _total]
	_hud_time.text = "ZEIT %.1f" % ((now - _start_time) / 1000.0)


func _process(_delta: float) -> void:
	if _follow:
		var target := Vector2(player.position.x + _lead, height / 2)
		_cam.position = _cam.position.lerp(target, 0.14)
	_cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount if now < _shake_until else Vector2.ZERO
	var left := _cam.get_screen_center_position().x - 480
	_bg.region_rect = Rect2(left * 0.5 / 3.0, 0, 320, 135)
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
		var node: Sprite2D = l["node"]
		for tw in l["tweens"]:
			(tw as Tween).kill()
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
		checkpoint_index = maxi(checkpoint_index, i)
		var best: Dictionary = _checkpoints[checkpoint_index]
		_spawn = Vector2(best["x"], best["floor"] - 42)
		var img: Sprite2D = cp["img"]
		img.texture = Art.tex("seed-1")
		img.scale = Vector2(1.8, 4.5)
		img.create_tween().tween_property(img, "scale", Vector2(3, 3), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		fx.leaves(Vector2(cp["x"], cp["floor"] - 40), 8)
		fx.text(Vector2(cp["x"], cp["floor"] - 110), "Checkpoint!", Color("#a6e07a"))
		Sfx.play("checkpoint")


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


func _lose_life() -> void:
	if player.lives >= 0 and player.lives < _hud_lives.size():
		var lost := _hud_lives[player.lives]
		lost.texture = Art.tex("leaf-wilt")
		lost.pivot_offset = lost.size / 2
		var tw := lost.create_tween().set_parallel().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(lost, "rotation_degrees", 35.0, 0.3)
		tw.tween_property(lost, "position:y", lost.position.y + 6, 0.3)
	shake(180, 0.012)
	flash_screen(Color(1, 0.3, 0.3, 0.45))
	Sfx.play("hurt")
	if player.lives <= 0:
		_game_over()


func _hurt(from_x: float) -> void:
	if _done or not player.hurt(now, from_x):
		return
	if _tutorial:  # im Tutorial gibt es kein „Nachsitzen“
		player.lives = 3
		flash_screen(Color(1, 0.3, 0.3, 0.45))
		Sfx.play("hurt")
		return
	fx.burst(player.position, Color("#ff5a5a"), 10)
	_lose_life()


## Sturz in den Abgrund: ein Leben weg, zurück zum letzten Setzling.
func _fall() -> void:
	if _done:
		return
	if _tutorial:
		Sfx.play("hurt")
		player.respawn(now, _spawn)
		return
	player.lives -= 1
	_lose_life()
	if player.lives > 0:
		player.respawn(now, _spawn)


# ====================================================================== Levelende

func _panel(title_text: String, body: String) -> Control:
	var root := Control.new()
	UI.screen(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(root)
	UI.rect(root, Rect2(_panel_x - 270, 125, 540, 330), Color(0.043, 0.043, 0.051, 0.95), 4, UI.YELLOW)
	UI.label(root, title_text, Vector2(_panel_x, 158), 24, UI.YELLOW)
	var l := UI.label(root, body, Vector2(_panel_x, 225), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 500)
	l.add_theme_constant_override("line_spacing", 12)
	return root


func _panel_buttons(root: Control, text: String, action: Callable) -> void:
	var first := UI.button(root, text, Vector2(_panel_x - 125, 395), action, 220, 50)
	UI.button(root, "Level", Vector2(_panel_x + 125, 395), func(): Nav.goto("levels"), 220, 50)
	first.grab_focus.call_deferred()


func _game_over() -> void:
	_done = true
	Sfx.play("over")
	var root := _panel("Nachsitzen!", "Alle Leben verloren.\nEs geht am letzten Setzling weiter.")
	var retry := func(): Nav.goto("game", { "level": level_index, "checkpoint": checkpoint_index })
	_panel_buttons(root, "Nochmal", retry)
	_report("over")
	if _bot and bot_retries < 5:
		bot_retries += 1
		get_tree().create_timer(0.8).timeout.connect(retry)


## Ziel erreicht: Die gesammelten Blätter fliegen in die Krone und der Ginkgo wird golden.
func _finish() -> void:
	_done = true
	if _tutorial:
		_tutorial.hide_box()
	var seconds := (now - _start_time) / 1000.0
	_follow = false
	_cam.create_tween().tween_property(_cam, "position:x", _goal_x - 230, 0.5).set_trans(Tween.TRANS_SINE)
	_panel_x = 310
	var n := mini(collected, 36)
	var share := float(collected) / _total if _total > 0 else 0.0
	var tw := create_tween()
	for i in n:
		tw.tween_interval(0.25 if i == 0 else 0.045)
		tw.tween_callback(_fly_leaf.bind(i, n, share))
	tw.tween_interval(0.65 + 0.62)
	tw.tween_callback(_show_result.bind(seconds))


func _fly_leaf(i: int, n: int, share: float) -> void:
	var start := view_rect().position + Vector2(252, 38)
	var leaf := Enemies.make_sprite(self, "leaf", start, 1.2, 18)
	var target := Vector2(_goal_x - 66 + randf() * 132, 405 - 234 + 12 + randf() * 84)
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
	var all := collected >= _total
	if all:
		fx.leaves(Vector2(_goal_x, 230), 30)
	Sfx.play("win")
	var reward := collected + _bonus + player.lives * 5
	var id: String = level["id"]
	var from_checkpoint := _start_checkpoint >= 0  # nach „Nachsitzen“ zählt die Zeit nicht als Bestzeit
	var best = Save.data["best_times"].get(id)
	var new_best: bool = not from_checkpoint and (best == null or seconds < best)
	if new_best:
		Save.data["best_times"][id] = seconds
	Save.data["best_leaves"][id] = maxi(int(Save.data["best_leaves"].get(id, 0)), collected)
	Save.data["progress"] = maxi(int(Save.data["progress"]), maxi(1, mini(level_index + 1, Levels.list.size() - 1)))
	Save.data["coins"] = int(Save.data["coins"]) + reward
	Save.persist()
	var lines := [
		"Blätter: %d/%d%s" % [collected, _total, "  ALLE!" if all else ""],
		("Zeit: %.1fs (ab Setzling)" % seconds) if from_checkpoint else ("Zeit: %.1fs%s" % [seconds, "  BESTZEIT!" if new_best else ""]),
		"+%d Ginkgo-Taler" % reward,
	]
	var root := _panel("Der Ginkgo leuchtet!" if all else "Geschafft!", "\n".join(lines))
	var has_next := level_index + 1 < Levels.list.size()
	_panel_buttons(root, "Weiter" if has_next else "Nochmal", func(): Nav.goto("game", { "level": level_index + 1 if has_next else level_index }))
	_report("win")


# ====================================================================== Testausgabe

func _report(result: String) -> void:
	if not (_bot or Nav.args.has("quit")):
		return
	print("BOT_RESULT level=%d result=%s lives=%d leaves=%d/%d time=%.1f retries=%d" % [
		level_index, result, player.lives, collected, _total, (now - _start_time) / 1000.0, bot_retries])
	if Nav.args.has("quit") and (result == "win" or not _bot or bot_retries >= 5):
		get_tree().create_timer(0.3).timeout.connect(get_tree().quit)


func _report_state() -> void:
	if Engine.get_physics_frames() % 60 == 0:
		print("BOT_STATE t=%.0f x=%.0f y=%.0f lives=%d leaves=%d" % [now / 1000.0, player.position.x, player.position.y, player.lives, collected])
