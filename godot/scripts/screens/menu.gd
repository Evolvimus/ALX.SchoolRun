extends Control
## Hauptmenü: links Titel, großer „Spielen“-Button und Kacheln, rechts die gewählte Figur auf einer Bühne.

var params := {}


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	_leaves()
	var e := UI.edges()

	# --- Kopfzeile rechts: Taler, Lehrer, Ton
	var sound := UI.icon_button(self, "icon-mute" if Save.data["muted"] else "icon-sound", Vector2(e.y - 46, 40), func(): pass, 52, 3.0)
	sound.pressed.connect(func():
		var muted := Sfx.toggle_mute()
		(sound.get_node("Icon") as TextureRect).texture = Art.tex("icon-mute" if muted else "icon-sound"))
	var coins := UI.chip(self, "icon-coin", "%d" % Save.data["coins"], e.y - 86, 40, Color("#ffd23f"), 12)
	var count := 0
	for t in Chars.teachers:
		if Save.is_unlocked(t["id"]):
			count += 1
	UI.chip(self, "icon-card", "%d/%d" % [count, Chars.teachers.size()], coins.position.x - 10, 40, UI.TEXT, 12)

	# --- Titel
	var logo := UI.image(self, "leaf", Vector2(96, 120), 3.4)
	logo.pivot_offset = logo.size / 2
	logo.rotation_degrees = -14
	var sway := logo.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	sway.tween_property(logo, "rotation_degrees", -4.0, 2.2)
	sway.tween_property(logo, "rotation_degrees", -14.0, 2.2)
	UI.tag(self, "ALX", Vector2(150, 86), UI.YELLOW, 10)
	var t := UI.label(self, "SCHOOLRUN", Vector2(146, 112), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 500)
	UI.outline(t, 10)
	UI.label(self, "Bring dem alten Ginkgo seine goldenen Blätter zurück.", Vector2(60, 168), 8, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 500)

	# --- Spielen: wer das Tutorial noch nicht kennt, startet dort; sonst geht es mit dem nächsten Level weiter
	var next := _next_level()
	var play := UI.primary(self, "", Vector2(280, 236), func():
		if next >= 0:
			Nav.goto("game", { "level": next })
		else:
			Nav.goto("levels"), 440, 84)
	UI.image(play, "icon-play", Vector2(46, 42), 3.0).modulate = UI.INK
	UI.label(play, "SPIELEN", Vector2(84, 22), 20, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, 340)
	var sub := "Alles geschafft · Schulplan öffnen"
	if next >= 0:
		var lv: Dictionary = Levels.list[next]
		sub = ("Los geht's: " if lv["kind"] == "tutorial" else "Weiter: %s · " % Levels.label(next)) + lv["name"]
	UI.label(play, sub, Vector2(84, 54), 8, Color("#6b4a00"), HORIZONTAL_ALIGNMENT_LEFT, 340)

	# --- Kacheln
	var found := 0
	for b in Bestiary.LIST:
		if b["id"] in Save.data["seen"]:
			found += 1
	var tiles := [
		["icon-map", "Schulplan", func(): Nav.goto("levels")],
		["bust-" + Save.data["selected"], "Figuren", func(): Nav.goto("album")],
		["icon-book", "Lexikon", func(): Nav.goto("lexikon")],
		["icon-code", "Code", func(): Nav.goto("redeem")],
		["icon-shop", "Shop", func(): Nav.goto("shop")],
	]
	var buttons: Array[Control] = [play]
	for i in tiles.size():
		var b := UI.tile(self, tiles[i][0], tiles[i][1], Vector2(60 + 42 + i * 89, 350), tiles[i][2], 82, 96, 40)
		buttons.append(b)
		if tiles[i][1] == "Lexikon":
			UI.label(b, "%d/%d" % [found, Bestiary.LIST.size()], Vector2(74, 8), 7, UI.BLUE, HORIZONTAL_ALIGNMENT_RIGHT, 70)
	for i in buttons.size():
		UI.pop_in(buttons[i], 0.04 * i)
	# Steuerung mit Pfeiltasten: von „Spielen“ nach unten in die Kachelreihe
	for i in range(1, buttons.size()):
		buttons[i].focus_neighbor_top = buttons[0].get_path()
	buttons[0].focus_neighbor_bottom = buttons[1].get_path()
	play.grab_focus.call_deferred()

	# --- Figur auf der Bühne
	var c := Chars.get_char(Save.data["selected"])
	var cx := 740.0
	UI.glow(self, Vector2(cx, 290), 170, Color(Art.col(Chars.RARITY_COLOR[c["rarity"]]), 0.28))
	var shadow := UI.glow(self, Vector2(cx, 394), 32, Color(0, 0, 0, 0.75))
	shadow.size = Vector2(240, 44)
	shadow.position = Vector2(cx - 120, 372)
	var fig := UI.image(self, "char-" + c["id"], Vector2(cx, 300), Chars.display_scale(c) * 1.7)
	fig.position.y = 394 - fig.size.y
	var tw := fig.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(fig, "position:y", fig.position.y - 6, 1.0)
	tw.tween_property(fig, "position:y", fig.position.y, 1.0)
	UI.label(self, c["name"], Vector2(cx, 420), 12, Color.WHITE)
	var rc: Color = Art.col(Chars.RARITY_COLOR[c["rarity"]])
	var rt := UI.tag(self, Chars.RARITY_LABEL[c["rarity"]].to_upper(), Vector2.ZERO, rc, 7)
	rt.position = Vector2(cx - rt.size.x / 2, 442)

	if Backend.test_mode:
		UI.label(self, "TESTMODUS · kein Server verbunden", Vector2(60, 508), 7, Color("#a05a6a"), HORIZONTAL_ALIGNMENT_LEFT, 400)
	UI.label(self, "an evolvimus production", Vector2(e.y - 20, 508), 7, Color("#3f4570"), HORIZONTAL_ALIGNMENT_RIGHT, 400)


## Nächstes spielbares, noch nicht geschafftes Level (zuerst das Tutorial), -1 wenn alles geschafft ist
func _next_level() -> int:
	for i in Levels.list.size():
		if Levels.list[i]["kind"] != "challenge" and Levels.is_unlocked(i) and not Levels.completed(i):
			return i
	return -1


## Wenige, langsam fallende Ginkgoblätter
func _leaves() -> void:
	var p := CPUParticles2D.new()
	p.texture = Art.tex("leaf")
	p.amount = 10
	p.lifetime = 12.0
	p.preprocess = 12.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(UI.vw() / 2, 4)
	p.position = Vector2(480, -20)
	p.direction = Vector2(0.3, 1)
	p.spread = 20.0
	p.gravity = Vector2(0, 2)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 55.0
	p.angular_velocity_min = -60.0
	p.angular_velocity_max = 60.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	p.color = Color(1, 1, 1, 0.35)
	add_child(p)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		Sfx.toggle_mute()
