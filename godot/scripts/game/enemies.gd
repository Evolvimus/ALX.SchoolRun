class_name Enemies
extends RefCounted
## Die Gegner. Keine Menschen: Tiere, Pflanzen und Geräte, die von sich aus etwas „tun“.
## Treffer werden über Rechtecke (hitbox) geprüft, nicht über die Physik-Engine.

const S := 3.0  # Gegner-Grafiken werden 3-fach gezeigt


static func make_sprite(parent: Node, key: String, pos: Vector2, scale := S, z := 8) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Art.tex(key)
	s.scale = Vector2(scale, scale)
	s.position = pos
	s.z_index = z
	parent.add_child(s)
	return s


## Sprite, dessen Ursprung unten in der Mitte liegt (steht auf dem Boden)
static func make_standing(parent: Node, key: String, pos: Vector2, scale := S, z := 8) -> Sprite2D:
	var s := make_sprite(parent, key, pos, scale, z)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	return s


static func approach(v: float, target: float, step: float) -> float:
	return minf(v + step, target) if v < target else maxf(v - step, target)


# ====================================================================== Basis

class Enemy extends RefCounted:
	## Kennung fürs Gegner-Lexikon (leer = taucht dort nicht auf)
	var kind := ""
	var alive := true
	var seen := false
	var hp := 1
	var hittable := true     ## mit Lineal/Hammer treffbar
	var stompable := false   ## Draufspringen besiegt ihn
	var bouncy := false      ## Draufspringen federt nur hoch
	var harmful := true      ## Berührung kostet ein Leben
	var reward := 2          ## Bonus-Taler beim Besiegen
	var last_swing := -1
	var game: Game

	func _init(g: Game) -> void:
		game = g

	func tick(_now: float, _dt: float) -> void:
		pass

	## Aktuelle Trefferfläche; leeres Rect2 = gerade nichts zu treffen
	func hitbox() -> Rect2:
		return Rect2()

	## Wo der Gegner gerade zu sehen ist (für das Lexikon); null = gerade unsichtbar
	func visible_at() -> Variant:
		var h := hitbox()
		return h.get_center() if h.has_area() else null

	func hit(dir: int, damage := 1) -> void:
		if not alive:
			return
		hp -= damage
		if hp <= 0:
			die(dir)
		else:
			Sfx.play("hit")
			on_hurt(dir)

	func stomp() -> void:
		die(0)

	func die(dir: int) -> void:
		if not alive:
			return
		var h := hitbox()
		alive = false
		on_die(dir)
		if h.has_area():
			game.enemy_defeated(self, Vector2(h.get_center().x, h.position.y))

	func on_hurt(_dir: int) -> void:
		pass

	func on_die(_dir: int) -> void:
		pass

	## Ohne Belohnung verschwinden (z. B. Arena-Gegner nach einem Fehlversuch)
	func remove() -> void:
		alive = false

	func flash(node: CanvasItem) -> void:
		node.modulate = Color(4, 4, 4)
		game.get_tree().create_timer(0.09).timeout.connect(func(): if is_instance_valid(node): node.modulate = Color.WHITE)


# ====================================================================== Staubmaus

## Läuft Streife und flitzt los, wenn man ihr zu nah kommt.
class DustMouse extends Enemy:
	var body: CharacterBody2D
	var sprite: Sprite2D
	var dir := -1
	var state := "walk"
	var until := 0.0
	var cool := 0.0
	var home: float

	func _init(g: Game, pos: Vector2) -> void:
		super(g)
		kind = "mouse"
		stompable = true
		home = pos.x
		body = CharacterBody2D.new()
		body.collision_layer = 4
		body.collision_mask = 1
		var shape := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(27, 18)
		shape.shape = r
		body.add_child(shape)
		body.position = pos
		g.add_child(body)
		sprite = Enemies.make_sprite(body, "mouse-0", Vector2(0, -3))

	func hitbox() -> Rect2:
		return Rect2(body.position - Vector2(13.5, 9), Vector2(27, 18))

	func tick(now: float, dt: float) -> void:
		var p := game.player
		var bottom := body.position.y + 9
		var wall := body.is_on_wall()
		var too_far := state == "walk" and (body.position.x - home) * dir > 160
		if body.is_on_floor() and (wall or too_far or not game.solid_at(body.position.x + dir * 22, bottom + 8)):
			dir *= -1
		if state == "walk" and now > cool and absf(p.position.x - body.position.x) < 200 and absf(p.position.y - body.position.y) < 70:
			state = "alert"
			until = now + 380
			dir = -1 if p.position.x < body.position.x else 1
			game.fx.text(body.position + Vector2(0, -30), "!", Color("#ff5a5a"))
			var tw := sprite.create_tween()
			tw.tween_property(sprite, "scale", Vector2(3.6, 2.1), 0.12)
			tw.tween_property(sprite, "scale", Vector2(3, 3), 0.12)
		elif state == "alert" and now > until:
			state = "dash"
			until = now + 650
		elif state == "dash" and now > until:
			state = "walk"
			cool = now + 1300
		var speed := 220.0 if state == "dash" else 0.0 if state == "alert" else 65.0
		body.velocity.x = dir * speed
		body.velocity.y = minf(body.velocity.y + 1400 * dt, 1000)
		body.move_and_slide()
		sprite.flip_h = dir > 0
		sprite.texture = Art.tex("mouse-1" if int(now / (70 if state == "dash" else 160)) % 2 else "mouse-0")
		if state == "dash" and body.is_on_floor() and int(now / 90) % 2:
			game.fx.dust(Vector2(body.position.x - dir * 12, bottom), 1)

	func remove() -> void:
		alive = false
		body.queue_free()

	func on_die(dir_: int) -> void:
		body.collision_layer = 0
		body.collision_mask = 0
		game.fx.dust(body.position, 10)
		var tw := body.create_tween().set_parallel()
		tw.tween_property(body, "position", body.position + Vector2(dir_ * 70, -40 if dir_ else 0), 0.32)
		tw.tween_property(sprite, "rotation", dir_ * TAU, 0.32)
		if dir_ == 0:
			tw.tween_property(sprite, "scale:y", 0.6, 0.32)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.32)
		tw.chain().tween_callback(body.queue_free)


# ====================================================================== Papierflieger

## Fliegen als Dreierformation durch den Raum. Ein Treffer knüllt sie zusammen.
class PaperPlane extends Enemy:
	var img: Sprite2D
	var origin: Vector2
	var idx: int
	var down := false
	var vy := 0.0
	var last_t := 0.0
	const OFF_X := [0, 58, 58]
	const OFF_Y := [0, -32, 32]

	func _init(g: Game, pos: Vector2, i: int) -> void:
		super(g)
		kind = "plane"
		reward = 1
		origin = pos
		idx = i
		img = Enemies.make_sprite(g, "plane", pos, Enemies.S, 9)

	func hitbox() -> Rect2:
		if down or img.modulate.a < 0.6:
			return Rect2()
		return Rect2(img.position - Vector2(18, 8), Vector2(36, 16))

	func tick(now: float, dt: float) -> void:
		var span := 780.0
		var t := fmod(now * 0.16, span)
		if t < last_t:  # neue Runde
			down = false
			img.texture = Art.tex("plane")
			img.rotation = 0
		last_t = t
		if not down:
			var wave := sin(t / 55.0 + idx)
			img.position = Vector2(origin.x - t + OFF_X[idx], origin.y + OFF_Y[idx] + wave * 10)
			img.rotation_degrees = wave * 6
			img.modulate.a = clampf(minf(t, span - t) / 60.0, 0, 1)
		else:
			vy += 900 * dt
			img.position += Vector2(-40 * dt, vy * dt)
			img.rotation += 7.3 * dt
			img.modulate.a = maxf(0, img.modulate.a - dt * 1.3)

	func hit(_dir: int, _damage := 1) -> void:
		if down:
			return
		down = true
		vy = -160
		img.texture = Art.tex("paperball")
		game.enemy_defeated(self, img.position - Vector2(0, 8))


# ====================================================================== Bücherwurm

## Frisst sich durchs Regal und taucht an wechselnden Löchern auf. Erst rascheln, dann schnappen.
class Bookworm extends Enemy:
	var img: Sprite2D
	var holes: Array
	var hole_imgs: Array[Sprite2D] = []
	var state := "hidden"
	var until := 900.0
	var f := 0.0  ## wie weit er herausschaut (0..1)
	var hole := 0

	func _init(g: Game, hole_list: Array) -> void:
		super(g)
		kind = "worm"
		hp = 2
		reward = 5
		holes = hole_list
		for h in holes:
			hole_imgs.append(Enemies.make_sprite(g, "hole", h + Vector2(0, 3), Enemies.S, 6))
		img = Enemies.make_sprite(g, "worm", Vector2.ZERO, Enemies.S, 7)
		img.centered = false
		img.region_enabled = true
		img.visible = false

	## Für den Testbot: wo taucht er gerade auf?
	func active_hole() -> Variant:
		return null if state == "hidden" else holes[hole]

	func hitbox() -> Rect2:
		if f < 0.45:
			return Rect2()
		var h: Vector2 = holes[hole]
		var height := 54.0 * f
		return Rect2(h.x - 11, h.y - height, 22, height)

	func tick(now: float, dt: float) -> void:
		var p := game.player
		var h: Vector2 = holes[hole]
		match state:
			"hidden":
				if now > until:
					var best := -1
					var best_d := INF
					for i in holes.size():
						if holes.size() > 1 and i == hole:
							continue
						var d := absf(holes[i].x - p.position.x)
						if d < best_d:
							best_d = d
							best = i
					if best_d < 520:
						hole = best
						state = "tell"
						until = now + 700
						if game.on_screen(holes[best].x):
							Sfx.play("rustle")
					else:
						until = now + 300
			"tell":
				hole_imgs[hole].position.x = h.x + sin(now / 22.0) * 2
				if int(now / 110) != int((now - dt * 1000) / 110):
					game.fx.burst(h - Vector2(0, 2), Color("#e8dcc0"), 2)
				if now > until:
					hole_imgs[hole].position.x = h.x
					state = "out"
					until = now + 1350
			"out":
				f = Enemies.approach(f, 1, dt / 0.16)
				if now > until:
					state = "back"
			"back":
				f = Enemies.approach(f, 0, dt / 0.2)
				if f <= 0:
					state = "hidden"
					until = now + (500.0 if hp < 2 else 900.0 + randf() * 500)
		h = holes[hole]
		img.visible = f > 0
		img.flip_h = p.position.x > h.x
		if f > 0:
			var rows := 18.0 * f
			img.region_rect = Rect2(0, 0, 9, rows)
			img.offset = Vector2(-4.5, -rows)
			img.position = Vector2(h.x + (sin(now / 130.0) * 3 if state == "out" else 0.0), h.y)

	func on_hurt(_dir: int) -> void:
		state = "back"
		flash(img)

	func on_die(dir_: int) -> void:
		var h: Vector2 = holes[hole]
		img.region_rect = Rect2(0, 0, 9, 18)
		img.offset = Vector2(-4.5, -18)
		img.position = h
		img.visible = true
		game.fx.burst(h - Vector2(0, 20), Color("#f4f4f4"), 12)
		game.fx.burst(h - Vector2(0, 20), Color("#9bc53d"), 8)
		var tw := img.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(img, "position", h + Vector2(dir_ * 90, -110), 0.52)
		tw.tween_property(img, "rotation", dir_ * 3 * PI, 0.52)
		tw.tween_property(img, "modulate:a", 0.0, 0.52)
		tw.chain().tween_callback(img.queue_free)


# ====================================================================== Laubbläser

## Bläst im Takt und schiebt die Figur weg. Mit dem Lineal zwei Hiebe, mit dem Hammer einer.
class Blower extends Enemy:
	var img: Sprite2D
	var on := false
	var until := 1200.0
	var next_streak := 0.0
	var base: Vector2
	var dir: int
	var zone: Rect2

	func _init(g: Game, ground_pos: Vector2, d: int) -> void:
		super(g)
		kind = "blower"
		hp = 2
		harmful = false
		reward = 5
		base = ground_pos
		dir = d
		img = Enemies.make_standing(g, "blower-0", ground_pos)
		img.flip_h = d > 0
		var length := 6 * 45.0
		zone = Rect2(ground_pos.x - 20 - length if d < 0 else ground_pos.x + 20, ground_pos.y - 112, length, 112)

	func hitbox() -> Rect2:
		return Rect2(base.x - 22, base.y - 32, 44, 32)

	func tick(now: float, _dt: float) -> void:
		if not alive:
			return
		if now > until:
			on = not on
			until = now + (2600.0 if on else 1700.0)
			if on and game.on_screen(base.x):
				Sfx.play("blow")
		var warming := not on and until - now < 450
		img.texture = Art.tex("blower-1" if on and int(now / 50) % 2 else "blower-0")
		img.position.x = base.x + (sin(now / 18.0) * 1.5 if warming else 0.0)
		if not on:
			return
		if now > next_streak and game.on_screen(base.x, 300):
			next_streak = now + 40
			game.fx.wind(Vector2(base.x + dir * 26, base.y - 8 - randf() * 96), dir, zone.size.x - 20)
		if zone.intersects(game.player.rect()):
			game.player.wind_target += dir * 265

	func on_hurt(_dir: int) -> void:
		game.fx.burst(base - Vector2(0, 18), Color("#ffd23f"), 8)
		flash(img)

	func on_die(_dir: int) -> void:
		on = false
		img.texture = Art.tex("blower-x")
		img.position.x = base.x
		game.fx.burst(base - Vector2(0, 18), Color("#ffd23f"), 14)
		game.fx.dust(base - Vector2(0, 24), 12)


# ====================================================================== Magnet

## Zieht abwechselnd an (blau) und stößt ab (rot). Kein Gegner zum Besiegen, sondern zum Ausnutzen.
class Magnet extends Enemy:
	const RADIUS := 250.0
	var img: Sprite2D
	var rings: Node2D
	var center: Vector2
	var _mode := 0

	func _init(g: Game, pos: Vector2) -> void:
		super(g)
		kind = "magnet"
		hittable = false
		harmful = false
		center = pos
		var rod := ColorRect.new()
		rod.color = Color("#555b66")
		rod.position = Vector2(pos.x - 1.5, 72)
		rod.size = Vector2(3, maxf(4, pos.y - 16 - 72))
		rod.z_index = 4
		g.add_child(rod)
		rings = Node2D.new()
		rings.z_index = 4
		rings.draw.connect(_draw_rings)
		g.add_child(rings)
		img = Enemies.make_sprite(g, "magnet", pos)

	func visible_at() -> Variant:
		return center

	## +1 = zieht an, -1 = stößt ab, 0 = schaltet gerade um
	func mode(now: float) -> int:
		var t := fmod(now, 6000)
		return 1 if t < 2600 else 0 if t < 3000 else -1 if t < 5600 else 0

	## Wie lange die aktuelle Phase noch dauert (ms)
	func remaining(now: float) -> float:
		var t := fmod(now, 6000)
		return 2600 - t if t < 2600 else 3000 - t if t < 3000 else 5600 - t if t < 5600 else 6000 - t

	func tick(now: float, _dt: float) -> void:
		_mode = mode(now)
		img.modulate = Color("#bfe0ff") if _mode > 0 else Color("#ffb8b8") if _mode < 0 else Color.WHITE
		if _mode == 0:
			img.modulate.a = 0.5 if int(now / 70) % 2 else 1.0
		rings.queue_redraw()
		if _mode == 0:
			return
		var p := game.player
		var d := center - p.position
		var dist := d.length()
		if dist < RADIUS and dist > 1:
			var force := 1250 * (1 - dist / RADIUS) * _mode
			p.force += Vector2(d.x / dist * force * 0.6, d.y / dist * force)

	func _draw_rings() -> void:
		if _mode == 0 or not game.on_screen(center.x, 300):
			return
		var now := game.now
		for i in 3:
			var k := fmod(now / 1100.0 + i / 3.0, 1.0)
			var r := RADIUS * (1 - k if _mode > 0 else k)
			var c := Color("#5ab0ff") if _mode > 0 else Color("#ff5a5a")
			c.a = 0.4 * sin(PI * k)
			rings.draw_arc(center, r, 0, TAU, 64, c, 3)


# ====================================================================== Bunsenbrenner

## Aus – Zündflamme – Stichflamme. Im Aus-Takt vorbeilaufen.
class Burner extends Enemy:
	const CYCLE := 3400.0
	var flame: Sprite2D
	var x: float
	var ground_y: float
	var offset_ms: float
	var was_on := false

	func _init(g: Game, ground_pos: Vector2, off: float) -> void:
		super(g)
		kind = "burner"
		hittable = false
		x = ground_pos.x
		ground_y = ground_pos.y
		offset_ms = off
		Enemies.make_standing(g, "burner", ground_pos)
		flame = Enemies.make_standing(g, "flame-0", ground_pos - Vector2(0, 22), Enemies.S, 7)
		flame.visible = false

	func _t(now: float) -> float:
		return fmod(now + offset_ms, CYCLE)

	func state(now: float) -> String:
		var t := _t(now)
		return "off" if t < 1500 else "tell" if t < 2000 else "on"

	## Wie lange er noch sicher aus ist (ms); 0, wenn er an ist oder gleich zündet
	func safe_for(now: float) -> float:
		var t := _t(now)
		return 1500 - t if t < 1500 else 0.0

	func _grow(now: float) -> float:
		return clampf((_t(now) - 2000) / 120.0, 0, 1)

	func visible_at() -> Variant:
		return Vector2(x, ground_y - 20)

	func hitbox() -> Rect2:
		var now := game.now
		if state(now) != "on":
			return Rect2()
		var height := 86 * _grow(now)
		return Rect2(x - 8, ground_y - 22 - height, 16, height)

	func tick(now: float, _dt: float) -> void:
		var s := state(now)
		if s == "on" and not was_on and game.on_screen(x):
			Sfx.play("flame")
		was_on = s == "on"
		flame.visible = s != "off"
		flame.texture = Art.tex("flame-1" if int(now / 60) % 2 else "flame-0")
		if s == "tell":
			flame.scale = Vector2(1.5, 0.36 + (int(now / 50) % 2) * 0.15)
		elif s == "on":
			flame.scale = Vector2(3, 3 * _grow(now) * (0.96 + (int(now / 60) % 2) * 0.04))


# ====================================================================== Raupe

## Sitzt auf einem großen Ginkgoblatt und frisst es auf, sobald man in die Nähe kommt. Schnell sein!
class Caterpillar extends Enemy:
	const VALUES := [5, 3, 1, 0]
	var leaf: Sprite2D
	var cat: Sprite2D
	var x: float
	var surface: float
	var eat := 0.0
	var bites := 0
	var started := false

	func _init(g: Game, ground_pos: Vector2) -> void:
		super(g)
		kind = "caterpillar"
		stompable = true
		reward = 3
		x = ground_pos.x
		surface = ground_pos.y
		leaf = Enemies.make_standing(g, "leaf", ground_pos, 3.0, 6)
		leaf.region_enabled = true
		leaf.region_rect = Rect2(0, 0, 21, 18)
		cat = Enemies.make_standing(g, "cat-0", Vector2(x + 3, surface - 50))

	func hitbox() -> Rect2:
		return Rect2(cat.position.x - 15, cat.position.y - 15, 30, 15)

	func tick(now: float, dt: float) -> void:
		var p := game.player
		if not started and absf(p.position.x - x) < 400 and game.on_screen(x, -40):
			started = true
			game.fx.text(Vector2(x, cat.position.y - 30), "Schnell!", Color("#ff8a5a"))
		cat.texture = Art.tex("cat-1" if int(now / 220) % 2 else "cat-0")
		if not started or bites >= 3:
			return
		eat += dt / 5.5
		var b := mini(3, int(eat * 3))
		if b > bites:
			bites = b
			Sfx.play("crunch")
			game.fx.burst(Vector2(x, cat.position.y), Color("#ffc928"), 6)
			if b >= 3:
				leaf.visible = false
				cat.scale = Vector2(3.9, 3.9)
				cat.offset = Vector2(-5, -5)
				cat.position.y = surface
			else:
				var cut := 18.0 * 0.3 * b
				leaf.region_rect = Rect2(0, cut, 21, 18 - cut)
				leaf.offset = Vector2(-10.5, -(18 - cut))
				cat.position.y = surface - 50 + cut * 3

	func on_die(dir_: int) -> void:
		var value: int = VALUES[bites]
		if value > 0:
			game.add_leaf(leaf, Vector2(x, surface - 22), value)
		game.fx.burst(cat.position - Vector2(0, 6), Color("#7ac74f"), 10)
		var tw := cat.create_tween().set_parallel()
		tw.tween_property(cat, "position", cat.position + Vector2(dir_ * 70, -50), 0.38)
		tw.tween_property(cat, "rotation", (dir_ if dir_ else 1) * 7.0, 0.38)
		tw.tween_property(cat, "modulate:a", 0.0, 0.38)
		tw.chain().tween_callback(cat.queue_free)


# ====================================================================== Basketball

## Springt im festen Rhythmus. Von der Seite tut er weh, von oben federt er hoch.
class Ball extends Enemy:
	const GRAVITY := 900.0
	var img: Sprite2D
	var pos: Vector2
	var vy := 0.0
	var floor_y: float
	var bounce_v: float

	func _init(g: Game, start: Vector2, floor_at: float) -> void:
		super(g)
		kind = "ball"
		hittable = false
		bouncy = true
		pos = start
		floor_y = floor_at - 15
		bounce_v = sqrt(2 * GRAVITY * maxf(10, floor_y - start.y))
		img = Enemies.make_sprite(g, "ball", start, 3.75)

	func hitbox() -> Rect2:
		return Rect2(pos - Vector2(12, 12), Vector2(24, 24))

	func tick(_now: float, dt: float) -> void:
		vy += GRAVITY * dt
		pos.y += vy * dt
		if pos.y >= floor_y:
			pos.y = floor_y
			vy = -bounce_v
		img.position = pos
		img.rotation += 3.8 * dt


# ====================================================================== Übungsscheibe

## Steht still und fällt beim ersten Treffer um (Tutorial).
class Target extends Enemy:
	var img: Sprite2D
	var base: Vector2

	func _init(g: Game, ground_pos: Vector2) -> void:
		super(g)
		harmful = false
		stompable = true
		reward = 1
		base = ground_pos
		img = Enemies.make_standing(g, "target", ground_pos)

	func hitbox() -> Rect2:
		return Rect2(base.x - 22, base.y - 66, 44, 66)

	func tick(now: float, _dt: float) -> void:
		if alive:
			img.rotation = sin(now / 400.0) * 0.035

	func on_die(dir_: int) -> void:
		game.fx.burst(base - Vector2(0, 40), Color("#d23b3b"), 10)
		game.fx.burst(base - Vector2(0, 40), Color("#f4f4f4"), 10)
		var tw := img.create_tween()
		tw.tween_property(img, "rotation", (dir_ if dir_ else 1) * PI / 2, 0.36).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.5)
		tw.tween_property(img, "modulate:a", 0.0, 0.4)
		tw.tween_callback(img.queue_free)


# ====================================================================== Boss: Der Kopierer

## Kündigt jeden Angriff an (Display blinkt rot). Ablauf in Runden:
##   Blätter werfen → Papierwelle über den Boden → überhitzen → Deckel auf (verwundbar!) → von vorn.
## Ab halber Energie: schneller, mehr Blätter, doppelte Welle.
## Schaden nur bei offenem Deckel: Lineal 1, Hammer 2, Draufspringen 2.
class Copier extends Enemy:
	const MAX_HP := 10
	var img: Sprite2D
	var base: Vector2
	var state := "sleep"
	var until := 0.0
	var step := 0
	var shots := 0
	var sheets: Array[Dictionary] = []
	var waves: Array[Dictionary] = []
	var awake := false
	var hit_until := 0.0

	func _init(g: Game, ground_pos: Vector2) -> void:
		super(g)
		kind = "copier"
		hp = MAX_HP
		reward = 40
		hittable = false
		base = ground_pos
		img = Enemies.make_standing(g, "copier", ground_pos, Enemies.S, 7)

	func phase2() -> bool:
		return hp <= MAX_HP / 2

	func hitbox() -> Rect2:
		return Rect2(base.x - 54, base.y - 84, 108, 84)

	## Wird von der Arena aufgerufen, wenn sich die Gitter schließen
	func wake(now: float) -> void:
		if awake:
			return
		awake = true
		state = "idle"
		until = now + 1200

	## Nach einem Fehlversuch: alles zurück auf Anfang
	func reset() -> void:
		awake = false
		state = "sleep"
		hp = MAX_HP
		step = 0
		_set_open(false)
		img.texture = Art.tex("copier")
		for sh in sheets:
			(sh["img"] as Node).queue_free()
		for w in waves:
			(w["img"] as Node).queue_free()
		sheets.clear()
		waves.clear()

	func _set_open(open: bool) -> void:
		hittable = open
		stompable = open
		harmful = not open
		img.texture = Art.tex("copier-open" if open else "copier")

	func tick(now: float, dt: float) -> void:
		_tick_projectiles(dt)
		if not awake or not alive:
			return
		var speed := 0.7 if phase2() else 1.0
		match state:
			"idle":
				if now > until:
					state = ["aim_sheets", "aim_wave", "overheat"][step % 3]
					step += 1
					until = now + 650 * speed
			"aim_sheets", "aim_wave":
				img.texture = Art.tex("copier-hot" if int(now / 90) % 2 else "copier")
				if now > until:
					img.texture = Art.tex("copier")
					if state == "aim_sheets":
						state = "sheets"
						shots = 5 if phase2() else 3
						until = now
					else:
						_spawn_wave()
						if phase2():
							state = "wave2"
							until = now + 700
						else:
							state = "idle"
							until = now + 1100 * speed
			"sheets":
				if now > until:
					_throw_sheet()
					shots -= 1
					until = now + 260 * speed
					if shots <= 0:
						state = "idle"
						until = now + 900 * speed
			"wave2":
				if now > until:
					_spawn_wave()
					state = "idle"
					until = now + 1100 * speed
			"overheat":
				img.position.x = base.x + sin(now / 15.0) * 2.5
				img.texture = Art.tex("copier-hot")
				if int(now / 120) % 2:
					game.fx.dust(base + Vector2(randf_range(-40, 40), -90), 1)
				if now > until + 500:
					img.position.x = base.x
					state = "open"
					_set_open(true)
					Sfx.play("land")
					until = now + 2200 * (0.85 if phase2() else 1.0)
			"open":
				if now > until:
					_set_open(false)
					state = "idle"
					until = now + 600

	func _throw_sheet() -> void:
		var p := game.player.position
		var from := base + Vector2(0, -60)
		var dx := clampf(p.x - from.x, -420, 420) + randf_range(-60, 60)
		var t := 0.95
		var v := Vector2(dx / t, -520)
		var sh := Enemies.make_sprite(game, "sheet", from, 3.0, 9)
		sheets.append({ "pos": from, "vel": v, "img": sh })
		Sfx.play("swing")

	func _spawn_wave() -> void:
		for d in [-1, 1]:
			var w := Enemies.make_standing(game, "paperwave", base + Vector2(d * 60, 0), 3.0, 9)
			w.flip_h = d < 0
			waves.append({ "x": base.x + d * 60, "dir": d, "img": w })
		Sfx.play("blow")
		game.shake(160, 0.006)

	func _tick_projectiles(dt: float) -> void:
		var pr := game.player.rect()
		for sh in sheets:
			sh["vel"].y += 900 * dt
			sh["pos"] += sh["vel"] * dt
			var img_: Sprite2D = sh["img"]
			img_.position = sh["pos"]
			img_.rotation += 6.0 * dt
			if Rect2(sh["pos"] - Vector2(10, 7), Vector2(20, 14)).intersects(pr):
				game.damage_player(sh["pos"].x)
				sh["dead"] = true
			elif sh["pos"].y > base.y + 10:
				game.fx.burst(sh["pos"], Color.WHITE, 3)
				sh["dead"] = true
		for w in waves:
			w["x"] += w["dir"] * (380.0 if phase2() else 330.0) * dt
			var img_: Sprite2D = w["img"]
			img_.position.x = w["x"]
			if Rect2(w["x"] - 20, base.y - 24, 40, 24).intersects(pr):
				game.damage_player(w["x"] - w["dir"] * 30)
			if absf(w["x"] - base.x) > 700:
				w["dead"] = true
		for list in [sheets, waves]:
			for item in list.filter(func(i): return i.get("dead", false)):
				(item["img"] as Node).queue_free()
				list.erase(item)

	## Wie lange der Deckel noch offen ist (ms); 0 wenn zu
	func open_left() -> float:
		return maxf(0.0, until - game.now) if state == "open" else 0.0

	func hit(dir: int, damage := 1) -> void:
		if not alive or state != "open" or game.now < hit_until:
			return
		hit_until = game.now + 300  # kurze Schutzzeit: pro offenem Deckel nur ein paar Treffer
		hp -= damage
		game.fx.burst(base + Vector2(0, -70), Color("#fff0a0"), 12)
		flash(img)
		Sfx.play("hit")
		if hp <= 0:
			die(dir)
		elif hp <= MAX_HP / 2 and hp + damage > MAX_HP / 2:
			game.fx.text(base + Vector2(0, -120), "Papierstau!", Color("#ff8a8a"))
			_set_open(false)
			state = "idle"
			until = game.now + 500

	func stomp() -> void:
		hit(0, 2)

	func on_die(_dir: int) -> void:
		hittable = false
		harmful = false
		for list in [sheets, waves]:
			for item in list:
				(item["img"] as Node).queue_free()
			list.clear()
		for i in 6:
			game.fx.burst(base + Vector2(randf_range(-50, 50), randf_range(-80, -10)), Color.WHITE, 10)
		game.fx.leaves(base + Vector2(0, -60), 20)
		game.shake(500, 0.015)
		Sfx.play("win")
		var tw := img.create_tween()
		for i in 6:
			tw.tween_property(img, "modulate:a", 0.2, 0.08)
			tw.tween_property(img, "modulate:a", 1.0, 0.08)
		tw.tween_property(img, "scale", Vector2(3.6, 0.3), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(img.queue_free)
