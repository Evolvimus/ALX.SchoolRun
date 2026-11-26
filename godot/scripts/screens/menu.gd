extends Control
## Hauptmenü

var params := {}


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	# Fallende Ginkgoblätter
	var p := CPUParticles2D.new()
	p.texture = Art.tex("leaf")
	p.amount = 20
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(480, 4)
	p.position = Vector2(480, -20)
	p.direction = Vector2(0, 1)
	p.spread = 25.0
	p.gravity = Vector2(0, 4)
	p.initial_velocity_min = 45.0
	p.initial_velocity_max = 90.0
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 0.9
	p.scale_amount_max = 1.6
	p.color = Color(1, 1, 1, 0.85)
	add_child(p)

	var logo := UI.image(self, "leaf", Vector2(112, 92), 6.0)
	logo.pivot_offset = logo.size / 2
	logo.rotation_degrees = -12
	UI.title(self, "ALX SchoolRun", 82, 36)
	UI.label(self, "Bring dem alten Ginkgo seine goldenen Blätter zurück!", Vector2(520, 126), 10)

	# Wer noch nie gespielt hat, startet direkt im Tutorial
	var tutorial_done: bool = Save.data["best_times"].has("tutorial")
	var play := UI.button(self, "Spielen", Vector2(480, 196), func(): Nav.goto("levels" if tutorial_done else "game", { "level": 0 }))
	UI.button(self, "Charaktere", Vector2(480, 252), func(): Nav.goto("album"))
	UI.button(self, "Gegner-Lexikon  %d/%d" % [_seen_count(), Bestiary.LIST.size()], Vector2(480, 308), func(): Nav.goto("lexikon"))
	UI.button(self, "Code einlösen", Vector2(480, 364), func(): Nav.goto("redeem"))
	UI.button(self, "Lehrerzimmer-Shop", Vector2(480, 420), func(): Nav.goto("shop"))
	play.grab_focus.call_deferred()

	var c := Chars.get_char(Save.data["selected"])
	var fig := UI.image(self, "char-" + c["id"], Vector2(800, 320), Chars.display_scale(c) * 1.6)
	var tw := fig.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(fig, "position:y", fig.position.y - 6, 0.9)
	tw.tween_property(fig, "position:y", fig.position.y, 0.9)
	UI.label(self, c["name"], Vector2(800, 448), 12)
	UI.label(self, "%d Ginkgo-Taler" % Save.data["coins"], Vector2(20, 20), 14, Color("#ffd700"), HORIZONTAL_ALIGNMENT_LEFT)
	var count := 0
	for t in Chars.teachers:
		if Save.is_unlocked(t["id"]):
			count += 1
	UI.label(self, "%d/%d Lehrer" % [count, Chars.teachers.size()], Vector2(940, 20), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)

	var sound := Button.new()
	sound.flat = true
	sound.add_theme_font_size_override("font_size", 10)
	sound.add_theme_color_override("font_color", Color("#c8c8d8"))
	sound.add_theme_color_override("font_hover_color", Color.WHITE)
	sound.text = "TON: AUS" if Save.data["muted"] else "TON: AN"
	sound.pressed.connect(func(): sound.text = "TON: AUS" if Sfx.toggle_mute() else "TON: AN")
	add_child(sound)
	sound.position = Vector2(14, 500)
	if Backend.test_mode:
		UI.label(self, "TESTMODUS (kein Server verbunden)", Vector2(480, 520), 9, Color("#ff7777"))


func _seen_count() -> int:
	var n := 0
	for b in Bestiary.LIST:
		if b["id"] in Save.data["seen"]:
			n += 1
	return n
