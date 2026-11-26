class_name Player
extends CharacterBody2D
## Spielfigur: Laufen mit Beschleunigung, Sprungpuffer, Coyote Time, variable Sprunghöhe,
## Doppelsprung/Gleiten je nach Fähigkeit, Nahkampf mit Lineal oder Hammer.
## Alle Figuren sind 90 px hoch (zwei Kacheln), die Trefferfläche ist 30x80 px.

const SIZE := Vector2(30, 80)
const GRAVITY := 1400.0

var game: Game
var char_data: Dictionary
var view: Sprite2D
var weapon: Sprite2D
var bubble: Label

var facing := 1
var lives := 3
## Hängt gerade an einer Sprossenwand
var climbing := false
## Worauf die Figur gerade steht (Rollwagen, Boden …) oder null
var floor_node: Node
## Wie lange man nach einem Treffer unverwundbar ist (ms)
var invuln_ms := 1500.0
var safe_until := 0.0
var swing_id := 0
## Von Gegnern pro Frame gesetzt: Wind (Zielgeschwindigkeit) und Kraft (Beschleunigung)
var wind_target := 0.0
var force := Vector2.ZERO

var _vx := 0.0
var _ext_vx := 0.0
var _lock_until := 0.0
var _attack_until := 0.0
var _next_attack := 0.0
var _last_ground := -9999.0
var _buffer_until := 0.0
var _prev_jump := false
var _prev_attack := false
var _jumping := false
var _air_jumps := 0
var _was_ground := true
var _fall_speed := 0.0
var _squash := Vector2.ONE
var _base_scale := 1.0
var _reach := 70.0
var _bubble_until := 0.0
var _next_quote := 0.0
var _quote_index := 0
var _next_sparkle := 0.0
var _id := ""


func setup(g: Game, c: Dictionary, pos: Vector2) -> void:
	game = g
	char_data = c
	_id = c["id"]
	position = pos
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	z_index = 10

	_base_scale = Chars.display_scale(c)
	view = Sprite2D.new()
	view.texture = Art.tex("char-" + _id)
	view.offset = Vector2(0, -view.texture.get_height() / 2.0)
	view.position = Vector2(0, SIZE.y / 2 + 1)
	add_child(view)

	var w: String = c["weapon"]
	weapon = Sprite2D.new()
	weapon.texture = Art.tex("hammer-gold" if w == "goldHammer" else "hammer" if w == "hammer" else "ruler")
	weapon.centered = false
	weapon.offset = Vector2(-0.08 * weapon.texture.get_width(), -weapon.texture.get_height() / 2.0)
	weapon.visible = false
	weapon.z_index = 1
	add_child(weapon)
	_reach = 90.0 if w == "goldHammer" else 70.0
	_quote_index = randi() % maxi(1, c["quotes"].size())
	_next_quote = 900.0


## Hammer: doppelter Schaden, zertrümmert Kisten
func heavy() -> bool:
	return char_data["weapon"] != "ruler"


func on_ground() -> bool:
	return is_on_floor()


func rect() -> Rect2:
	return Rect2(position - SIZE / 2, SIZE)


func bottom() -> float:
	return position.y + SIZE.y / 2


## Trefferzone der Waffe, solange der Schlag aktiv ist; leeres Rect2 sonst
func attack_rect(now: float) -> Rect2:
	if now >= _attack_until:
		return Rect2()
	var x := position.x - 4 if facing > 0 else position.x - _reach + 4
	return Rect2(x, position.y - SIZE.y / 2 - 16, _reach, SIZE.y + 20)


func tick(now: float, dt: float, c: Dictionary) -> void:
	var ground := is_on_floor()
	var locked := now < _lock_until
	var max_speed := 400.0 if Chars.has_ability(char_data, "speed") else 300.0
	var jump_v := -780.0 if Chars.has_ability(char_data, "highJump") else -640.0

	# Landen
	if ground and not _was_ground and _fall_speed > 260:
		_squash_to(Vector2(1.18, 0.82))
		game.fx.dust(Vector2(position.x, bottom()), 5)
		Sfx.play("land")
	if ground:
		_last_ground = now
		_air_jumps = 1 if Chars.has_ability(char_data, "doubleJump") else 0
	_was_ground = ground
	_fall_speed = velocity.y

	# Laufen mit Beschleunigung und Bremsen
	var dir := 0 if locked else int(c["right"]) - int(c["left"])
	if dir != 0:
		if ground and signf(_vx) == -dir and absf(_vx) > 150:
			game.fx.dust(Vector2(position.x, bottom()), 2)
		_vx = Enemies.approach(_vx, dir * max_speed, (2600.0 if ground else 1900.0) * dt)
		facing = dir
	elif not locked:
		_vx = Enemies.approach(_vx, 0, (3000.0 if ground else 900.0) * dt)
	if is_on_wall() and signf(get_wall_normal().x) == -signf(_vx):
		_vx = 0

	# Klettern an der Sprossenwand: hoch/runter, mit Richtung + Sprung seitlich abspringen
	var on_ladder: bool = game.ladder_at(position) or game.ladder_at(Vector2(position.x, bottom() - 4))
	if climbing:
		if not on_ladder or locked:
			climbing = false
		elif c["jump"] and not _prev_jump and dir != 0:
			climbing = false
			_vx = dir * 220.0
			_jump(jump_v * 0.75)
			Sfx.play("jump")
		else:
			var vdir := int(c["down"]) - int(c["up"])
			velocity = Vector2(dir * 110.0, vdir * 170.0)
			_vx = 0
			_ext_vx = 0
			move_and_slide()
			if vdir > 0 and is_on_floor():
				climbing = false
			_prev_jump = c["jump"]
			_prev_attack = c["attack"]
			_was_ground = true
			floor_node = null
			_draw_view(now, true, vdir != 0 or dir != 0)
			return
	elif not locked and on_ladder and c["up"]:
		climbing = true
		velocity = Vector2.ZERO
	elif not locked and ground and c["down"] and game.ladder_at(Vector2(position.x, bottom() + 12)):
		climbing = true  # von oben in die Sprossenwand einsteigen
		position.y += 12
		velocity = Vector2.ZERO

	# Springen: Sprungpuffer + Coyote Time + variable Höhe
	var pressed: bool = c["jump"] and not _prev_jump
	if pressed:
		_buffer_until = now + 130
	if not locked and now < _buffer_until and now - _last_ground < 110:
		_jump(jump_v)
		Sfx.play("jump")
	elif not locked and pressed and not ground and _air_jumps > 0:
		_air_jumps -= 1
		_jump(jump_v * 0.92)
		Sfx.play("air_jump")
	if _jumping and not c["jump"] and velocity.y < -240:
		velocity.y *= 0.5
		_jumping = false
	if velocity.y >= 0:
		_jumping = false
	_prev_jump = c["jump"]

	# Schwerkraft, äußere Kräfte (Magnet) und Wind
	velocity.y = minf(velocity.y + (GRAVITY + force.y) * dt, 1000)
	if Chars.has_ability(char_data, "glide") and c["jump"] and velocity.y > 120:
		velocity.y = 120
	_ext_vx += force.x * dt
	_ext_vx = Enemies.approach(_ext_vx, wind_target, 1500 * dt) if wind_target != 0 else Enemies.approach(_ext_vx, 0, 520 * dt)
	velocity.x = _vx + _ext_vx
	move_and_slide()
	floor_node = null
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other is Node and col.get_normal().y < -0.5:
			floor_node = other
		if other is Node and (other as Node).is_in_group("crate") and Chars.has_ability(char_data, "smash"):
			game.break_crate(other)

	# Schlag
	if not locked and c["attack"] and not _prev_attack and now >= _next_attack:
		swing_id += 1
		_attack_until = now + 150
		_next_attack = now + 320
		Sfx.play("heavy_swing" if heavy() else "swing")
	_prev_attack = c["attack"]

	# Sprüche: kurz nach dem Start und danach ab und zu
	var quotes: Array = char_data["quotes"]
	if quotes.size() > 0 and now >= _next_quote:
		say(quotes[_quote_index % quotes.size()], now)
		_quote_index += 1
		_next_quote = now + randf_range(22000, 32000)
	# Mythisch: Glitzer-Spur
	if char_data["rarity"] == "mythisch" and now >= _next_sparkle and (dir != 0 or not ground):
		_next_sparkle = now + 60
		game.fx.burst(position + Vector2(randf_range(-8, 8), randf_range(-20, 20)), Color("#ffd84a") if randf() < 0.5 else Color("#ff7fbf"), 1)

	_draw_view(now, is_on_floor(), dir != 0)


## Sprechblase über dem Kopf
func say(text: String, now: float, ms := 3200.0) -> void:
	if bubble:
		bubble.queue_free()
	bubble = Label.new()
	bubble.text = text
	bubble.add_theme_font_size_override("font_size", 9)
	bubble.add_theme_color_override("font_color", Color("#1a1a2e"))
	bubble.add_theme_constant_override("line_spacing", 4)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.94)
	bg.set_content_margin_all(7)
	bg.set_corner_radius_all(4)
	bubble.add_theme_stylebox_override("normal", bg)
	bubble.z_index = 17
	bubble.z_as_relative = false
	add_child(bubble)
	bubble.reset_size()
	_bubble_until = now + ms


func _jump(v: float) -> void:
	velocity.y = v
	_last_ground = -9999
	_buffer_until = 0
	_jumping = true
	_squash_to(Vector2(0.86, 1.16))
	game.fx.dust(Vector2(position.x, bottom()), 3)


## Hochfedern (Matte, Ball, besiegter Gegner) – wird nicht durch Loslassen der Taste gekürzt.
func bounce(v: float) -> void:
	velocity.y = v
	_jumping = false
	_air_jumps = 1 if Chars.has_ability(char_data, "doubleJump") else 0
	_squash_to(Vector2(0.82, 1.2))
	Sfx.play("bounce")


## Treffer einstecken. Gibt true zurück, wenn wirklich ein Leben verloren ging.
func hurt(now: float, from_x: float) -> bool:
	if now < safe_until:
		return false
	lives -= 1
	safe_until = now + invuln_ms
	_lock_until = now + 260
	_vx = (-1 if position.x < from_x else 1) * 260.0
	velocity.y = -380
	return true


func respawn(now: float, pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	climbing = false
	_vx = 0
	_ext_vx = 0
	safe_until = now + 1500


func stop() -> void:
	_vx = Enemies.approach(_vx, 0, 60)
	velocity = Vector2(_vx, minf(velocity.y + GRAVITY / 60.0, 1000))
	move_and_slide()


func _squash_to(s: Vector2) -> void:
	_squash = s
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_squash", Vector2.ONE, 0.18)


func _draw_view(now: float, ground: bool, moving: bool) -> void:
	var frame := "-j" if not ground else ("-w1" if int(now / 95) % 2 else "-w2") if moving else ("-i" if int(now / 520) % 2 else "")
	view.texture = Art.tex("char-" + _id + frame)
	view.offset = Vector2(0, -view.texture.get_height() / 2.0)
	view.flip_h = facing < 0
	view.scale = _base_scale * _squash
	view.modulate.a = 0.3 if now < safe_until and int(now / 80) % 2 else 1.0

	if bubble:
		if now >= _bubble_until:
			bubble.queue_free()
			bubble = null
		else:
			bubble.position = Vector2(-bubble.size.x / 2, -SIZE.y / 2 - 22 - bubble.size.y)

	var swinging := now < _attack_until
	weapon.visible = swinging
	if swinging:
		var p := 1.0 - (_attack_until - now) / 150.0
		var a := lerpf(-115, 40, p)
		var k := 3.75 if char_data["weapon"] == "goldHammer" else 3.0
		weapon.position = Vector2(facing * 6, -6)
		weapon.scale = Vector2(facing * k, k)
		weapon.rotation_degrees = a * facing
