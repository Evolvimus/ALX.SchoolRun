extends Control
## Levelauswahl mit Bestzeit und gesammelten Blättern

var params := {}


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	UI.title(self, "Level wählen", 44)
	# Schwierigkeitsstufe umschalten
	var order := ["entspannt", "normal", "abi"]
	var info := { "entspannt": "5 Leben · nach Sturz geht es direkt daneben weiter", "normal": "3 Leben · zurück zum Setzling", "abi": "1 Leben · 50 % mehr Taler" }
	var diff_label := UI.label(self, "", Vector2(940, 62), 8, Color("#c8c8d8"), HORIZONTAL_ALIGNMENT_RIGHT, 420)
	var diff := UI.button(self, "", Vector2(840, 34), func(): pass, 200, 36)
	diff.add_theme_font_size_override("font_size", 10)
	var show := func():
		var d: String = Save.data["difficulty"]
		diff.text = "Stufe: " + Game.DIFFICULTY[d]["label"]
		diff_label.text = info[d]
	show.call()
	diff.pressed.connect(func():
		Save.data["difficulty"] = order[(order.find(Save.data["difficulty"]) + 1) % order.size()]
		Save.persist()
		show.call())
	var n := Levels.list.size()
	var step := minf(290.0, 920.0 / n)
	var cw := step - 18
	var first: Button
	for i in n:
		var lv: Dictionary = Levels.list[i]
		var x := 480 + (i - (n - 1) / 2.0) * step
		var y := 262.0
		var open := i <= maxi(int(Save.data["progress"]), 1)
		var id: String = lv["id"]
		var best = Save.data["best_times"].get(id)
		var card := Button.new()
		var style := StyleBoxFlat.new()
		style.bg_color = UI.NAVY
		style.border_color = UI.YELLOW if open else Color("#444a66")
		style.set_border_width_all(4)
		var hover := style.duplicate()
		hover.bg_color = Color("#20254a")
		var focus := hover.duplicate()
		focus.border_color = Color.WHITE
		card.add_theme_stylebox_override("normal", style)
		card.add_theme_stylebox_override("hover", hover)
		card.add_theme_stylebox_override("pressed", hover)
		card.add_theme_stylebox_override("focus", focus)
		card.add_theme_stylebox_override("disabled", style)
		card.disabled = not open
		add_child(card)
		card.position = Vector2(x - cw / 2, y - 150)
		card.size = Vector2(cw, 300)
		var preview := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = Art.tex(lv["bg"])
		at.region = Rect2(40, 0, (cw - 20) / 3.0 * 3, 130 * 1.03)
		preview.texture = at
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview.modulate.a = 1.0 if open else 0.35
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		preview.position = Vector2(10, 10)
		preview.size = Vector2(cw - 20, 130)
		var label := Levels.label(i)
		var dim := Color("#666c88")
		UI.label(card, label, Vector2(cw / 2, 148), 14 if label.length() > 2 else 24, UI.YELLOW if open else dim, HORIZONTAL_ALIGNMENT_CENTER, cw)
		UI.label(card, lv["name"], Vector2(cw / 2, 184), 10 if lv["name"].length() < 14 else 9, Color.WHITE if open else dim, HORIZONTAL_ALIGNMENT_CENTER, cw)
		if lv.has("tutorial") and best == null:
			var tag := UI.label(self, "START HIER!", Vector2(x, y - 176), 10, UI.INK, HORIZONTAL_ALIGNMENT_CENTER, 130)
			var s := StyleBoxFlat.new()
			s.bg_color = Color("#a6e07a")
			s.set_content_margin_all(5)
			tag.add_theme_stylebox_override("normal", s)
			var tw := tag.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
			tw.tween_property(tag, "position:y", tag.position.y - 6, 0.6)
			tw.tween_property(tag, "position:y", tag.position.y, 0.6)
		if not open:
			UI.label(card, "Gesperrt", Vector2(cw / 2, 240), 10, dim, HORIZONTAL_ALIGNMENT_CENTER, cw)
			continue
		var got := int(Save.data["best_leaves"].get(id, 0))
		var hefte_total := Levels.count_hefte(lv)
		var lx := cw / 2 - (62.0 if hefte_total > 0 else 30.0)
		UI.image(card, "leaf", Vector2(lx, 222), 1.0)
		UI.label(card, "%d/%d" % [got, Levels.count_leaves(lv)], Vector2(lx + 16, 217), 9, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_LEFT, cw)
		if hefte_total > 0:
			var owned: Array = Save.data["hefte"].get(id, [])
			UI.image(card, "heft", Vector2(cw / 2 + 34, 222), 1.6)
			UI.label(card, "%d/%d" % [owned.size(), hefte_total], Vector2(cw / 2 + 46, 217), 9, Color("#8fb4ff"), HORIZONTAL_ALIGNMENT_LEFT, cw)
		var medals: Dictionary = Save.data["medals"].get(id, {})
		for m in Game.MEDALS.size():
			var icon := UI.image(card, "medal-" + Game.MEDALS[m][0], Vector2(cw / 2 + (m - 1) * 30, 250), 2.0)
			if not medals.get(Game.MEDALS[m][0], false):
				icon.modulate = Color(0.2, 0.2, 0.26)
		UI.label(card, "Bestzeit %.1fs" % best if best != null else "Noch offen", Vector2(cw / 2, 272), 8, Color("#c8c8d8"), HORIZONTAL_ALIGNMENT_CENTER, cw)
		card.pressed.connect(func():
			Sfx.play("click")
			Nav.goto("game", { "level": i }))
		if first == null:
			first = card
	UI.back_button(self)
	if first:
		first.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
