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

	# Sprossenwand: hochklettern, wenn rechts eine Wand ist
	var wall_ahead := g.solid_at(r.end.x + 14, feet) or g.solid_at(r.end.x + 14, r.position.y + 10)
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
		var floor_ahead := g.solid_at(r.get_center().x + 10, r.end.y + 10)
		if on_mover:
			# zum rechten Rand des Wagens gehen und absteigen, sobald vorne fester Boden auf gleicher Höhe ist
			var edge: float = (p.floor_node as Node2D).position.x + 45
			if r.end.x > edge - 6 and not (g.solid_at(r.end.x + 12, r.end.y + 10) or g.solid_at(r.end.x + 12, r.end.y + 30)):
				c["right"] = false
		else:
			if g.solid_at(r.end.x + 14, feet) or g.crate_at(r.end.x + 14, feet) or g.door_at(r.end.x + 14, feet):
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
	if not c["right"]:
		stuck_since = now
		want_jump = false
	if want_jump and now > hold_until + 60:
		hold_until = now + 420
	c["jump"] = now < hold_until
	return c


## Sucht einen Rollwagen/Aufzug, dessen Strecke direkt vor der Figur beginnt.
## Ergebnis: {} (keiner) oder { here = true/false } (steht er gerade bündig an der Kante?)
func _mover_ahead(g: Game, r: Rect2) -> Dictionary:
	for m in g.movers:
		var origin: Vector2 = m["origin"]
		var start_left := origin.x - 45
		if start_left - r.end.x > 60 or start_left - r.end.x < -50 or absf(origin.y - 9 - r.end.y) > 30:
			continue
		return { "here": g.mover_phase(m)[1] > 350 }  # steht am Start und bleibt noch kurz
	return {}
