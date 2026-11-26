class_name Bot
extends RefCounted
## Einfacher Testbot (Startoption --bot): läuft nach rechts, springt über Lücken und Hindernisse,
## schlägt nach Gegnern, klettert Sprossenwände hoch, fährt mit Rollwagen und Aufzügen
## und wartet bei Brennern, Magneten und Bällen. Er prüft, ob ein Level lösbar ist.

var hold_until := 0.0
var stuck_x := 0.0
var stuck_since := 0.0


func controls(g: Game, now: float) -> Dictionary:
	var p := g.player
	var r := p.rect()
	var c := { "left": false, "right": true, "jump": false, "attack": false, "up": false, "down": false }
	var ground := p.on_ground()
	var want_jump := false
	var feet := r.end.y - 6

	# Bosskampf und Arena haben eigene Regeln
	if g.boss and g.boss.awake and g.boss.alive:
		return _fight_boss(g, now, c)
	var arena := g.active_arena()
	if not arena.is_empty():
		return _fight_arena(g, now, c, arena)

	# Sprossenwand: hochklettern, wenn rechts eine Wand ist
	var wall_ahead := g.solid_at(r.end.x + 14, feet) or g.solid_at(r.end.x + 14, r.position.y + 10) or g.crate_at(r.end.x + 14, feet)
	if p.climbing or ((g.ladder_at(p.position) or g.ladder_at(Vector2(p.position.x, feet))) and wall_ahead):
		c["up"] = true
		c["right"] = false
		stuck_since = now
		return c

	for e in g.enemies:
		if not e.alive:
			continue
		if e is Enemies.Burner:
			var dx: float = e.x - p.position.x
			if dx > 0 and dx < 105 and e.safe_for(now) < 650:
				c["right"] = false
			continue
		if e is Enemies.Magnet:
			var dx: float = e.center.x - p.position.x
			if ground and dx > 60 and dx < 300 and not (e.mode(now) > 0 and e.remaining(now) > 1500):
				c["right"] = false
			continue
		if e is Enemies.Bookworm:
			var h = e.active_hole()
			if h != null and absf(h.y - r.end.y) < 60 and h.x - p.position.x > 30 and h.x - p.position.x < 95 and not e.hitbox().has_area():
				c["right"] = false  # vor dem raschelnden Loch warten
		var hb: Rect2 = e.hitbox()
		if not hb.has_area():
			continue
		var dx := hb.get_center().x - p.position.x
		var dy := hb.get_center().y - p.position.y
		var reach := 135.0 if e is Enemies.PaperPlane else 88.0
		if e.hittable and dx > -20 and dx < reach and absf(dy) < 70:
			c["attack"] = int(now / 70) % 2 == 0
		if e is Enemies.Ball and ground and dx > 20 and dx < 125 and not (e.vy < 0 and hb.end.y < r.position.y - 20):
			c["right"] = false  # warten, bis der Ball wieder hochsteigt

	if ground:
		var on_mover := p.floor_node is AnimatableBody2D
		var floor_ahead := g.solid_at(r.get_center().x + 10, r.end.y + 10) or _mover_at(g, r.get_center().x + 10, r.end.y + 6)
		# gerade von einem Wagen auf festen Boden gestiegen (unter der Mitte noch Lücke, vorne schon Boden)
		if not g.solid_at(r.get_center().x, r.end.y + 10) and g.solid_at(r.end.x + 8, r.end.y + 10):
			floor_ahead = true
		var lift_m := _mover_of(g, p.floor_node)
		if on_mover and not lift_m.is_empty() and lift_m["axis"] == Vector2.UP:
			# Aufzug: mittig stehen bleiben, oben angekommen nach rechts auf den Sims springen
			var center: float = (p.floor_node as Node2D).position.x
			if g.mover_phase(lift_m)[0] > 0.99:
				want_jump = true
			else:
				c["right"] = p.position.x < center - 12
				c["left"] = p.position.x > center + 12
		elif on_mover:
			# zum rechten Rand des Wagens gehen und absteigen, sobald vorne fester Boden auf gleicher Höhe ist
			var edge: float = (p.floor_node as Node2D).position.x + 45
			if r.end.x > edge - 6 and not (g.solid_at(r.end.x + 12, r.end.y + 10) or g.solid_at(r.end.x + 12, r.end.y + 30)):
				c["right"] = false
		else:
			var lift := _lift_ahead(g, r)
			if not lift.is_empty():
				if not lift["here"]:
					c["right"] = false
				elif lift["dx"] < 22 and now > hold_until + 60:
					hold_until = now + 90  # kurzer Hüpfer auf den Aufzug, solange er unten steht
			elif g.solid_at(r.end.x + 14, feet) or g.crate_at(r.end.x + 14, feet) or g.door_at(r.end.x + 14, feet):
				want_jump = true  # Wand
			if not floor_ahead:
				# Abgrund: Gibt es hier einen Rollwagen oder Aufzug? Dann warten, bis er da ist, und draufgehen.
				var ride := _mover_ahead(g, r)
				if ride.is_empty():
					want_jump = true
				elif not ride["here"]:
					c["right"] = false
			for s in g.spikes:
				if s.position.x - r.end.x < 34 and s.end.x > r.position.x and absf(s.end.y - r.end.y) < 40:
					want_jump = true
		if absf(p.position.x - stuck_x) > 8:
			stuck_x = p.position.x
			stuck_since = now
		elif c["right"] and now - stuck_since > 2500:
			want_jump = true
			c["attack"] = true
			stuck_since = now
	elif not p.climbing:
		# in der Luft über einem Aufzug: zur Mitte steuern
		for m in g.movers:
			if m["axis"] == Vector2.UP:
				var pos: Vector2 = (m["body"] as Node2D).position
				if absf(pos.x - p.position.x) < 70 and pos.y > r.end.y - 10 and pos.y - r.end.y < 160 and g.mover_phase(m)[0] < 0.5:
					c["right"] = p.position.x < pos.x - 10
					c["left"] = p.position.x > pos.x + 10
	if not c["right"]:
		stuck_since = now
		want_jump = false
	if want_jump and now > hold_until + 60:
		hold_until = now + 420
	c["jump"] = now < hold_until
	return c


func _mover_of(g: Game, body: Node) -> Dictionary:
	for m in g.movers:
		if m["body"] == body:
			return m
	return {}


## Steht an dieser Stelle gerade ein Rollwagen/Aufzug?
func _mover_at(g: Game, x: float, y: float) -> bool:
	for m in g.movers:
		var pos: Vector2 = (m["body"] as Node2D).position
		if absf(pos.x - x) < 45 and absf(pos.y - y) < 14:
			return true
	return false


## Aufzug, der direkt vor der Figur auf dem Boden steht: {} oder { here = steht unten und bleibt noch kurz }
func _lift_ahead(g: Game, r: Rect2) -> Dictionary:
	for m in g.movers:
		if m["axis"] != Vector2.UP:
			continue
		var origin: Vector2 = m["origin"]
		var dx := (origin.x - 45) - r.end.x
		if dx > -10 and dx < 70 and absf(origin.y + 9 - r.end.y) < 12:
			return { "here": g.mover_phase(m)[1] > 650, "dx": dx }
	return {}


## Arena: zum nächsten Gegner laufen und zuschlagen
func _fight_arena(g: Game, now: float, c: Dictionary, arena: Dictionary) -> Dictionary:
	var p := g.player
	var target = null
	var best := INF
	for e in arena["spawned"]:
		if e.alive:
			var d := absf(e.hitbox().get_center().x - p.position.x)
			if d < best:
				best = d
				target = e
	c["right"] = false
	if target == null:
		return c
	var dx: float = target.hitbox().get_center().x - p.position.x
	if absf(dx) > 50:
		c["right"] = dx > 0
		c["left"] = dx < 0
	elif signf(dx) != p.facing and absf(dx) > 8:
		c["right"] = dx > 0
		c["left"] = dx < 0
	if absf(dx) < 85 and signf(dx) == p.facing:
		c["attack"] = int(now / 70) % 2 == 0
	return c


## Boss: Abstand halten, Papierwellen überspringen, bei offenem Deckel hinlaufen und zuschlagen
func _fight_boss(g: Game, now: float, c: Dictionary) -> Dictionary:
	var p := g.player
	var b := g.boss
	var dx := b.base.x - p.position.x
	c["right"] = false
	if b.state == "open" and b.open_left() > 380:
		if absf(dx) > 70:
			c["right"] = dx > 0
			c["left"] = dx < 0
		elif signf(dx) != p.facing:
			c["right"] = dx > 0
			c["left"] = dx < 0
		c["attack"] = int(now / 70) % 2 == 0
	else:
		# auf ca. 260 px Abstand gehen (auf der Seite, auf der man gerade steht)
		var side := -1.0 if dx > 0 else 1.0
		var want: float = b.base.x + side * 260
		if absf(want - p.position.x) > 30:
			c["right"] = want > p.position.x
			c["left"] = want < p.position.x
	# fallenden Blättern ausweichen (vom Boss weg)
	for sh in b.sheets:
		var sx: float = sh["pos"].x + sh["vel"].x * 0.25
		if sh["vel"].y > -200 and absf(sx - p.position.x) < 60 and sh["pos"].y < p.position.y:
			var away := -1.0 if dx > 0 else 1.0
			c["right"] = away > 0
			c["left"] = away < 0
	for w in b.waves:
		var wd: float = w["x"] - p.position.x
		if signf(wd) == -signf(w["dir"]) and absf(wd) < 130 and p.on_ground():
			c["jump"] = true
			hold_until = now + 420
	if now < hold_until:
		c["jump"] = true
	return c


## Sucht einen Rollwagen/Aufzug, dessen Strecke direkt vor der Figur beginnt.
## Ergebnis: {} (keiner) oder { here = true/false } (steht er gerade bündig an der Kante?)
func _mover_ahead(g: Game, r: Rect2) -> Dictionary:
	for m in g.movers:
		if m["axis"] == Vector2.UP:
			continue
		var origin: Vector2 = m["origin"]
		var start_left := origin.x - 45
		if start_left - r.end.x > 60 or start_left - r.end.x < -50 or absf(origin.y - 9 - r.end.y) > 30:
			continue
		return { "here": g.mover_phase(m)[1] > 350 }  # steht am Start und bleibt noch kurz
	return {}
