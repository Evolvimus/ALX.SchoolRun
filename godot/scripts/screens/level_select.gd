extends Control
## Levelauswahl mit Bestzeit und gesammelten Blättern

var params := {}


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	UI.title(self, "Level wählen", 44)
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
		UI.label(card, label, Vector2(cw / 2, 152), 16 if label.length() > 2 else 26, UI.YELLOW if open else dim, HORIZONTAL_ALIGNMENT_CENTER, cw)
		UI.label(card, lv["name"], Vector2(cw / 2, 192), 11, Color.WHITE if open else dim, HORIZONTAL_ALIGNMENT_CENTER, cw)
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
		UI.image(card, "leaf", Vector2(cw / 2 - 52, 236), 1.1)
		UI.label(card, "%d/%d" % [got, Levels.count_leaves(lv)], Vector2(cw / 2 - 30, 230), 11, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_LEFT, cw)
		UI.label(card, "Bestzeit %.1fs" % best if best != null else "Noch offen", Vector2(cw / 2, 268), 9, Color("#c8c8d8"), HORIZONTAL_ALIGNMENT_CENTER, cw)
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
