class_name SettingsPanel
extends Control
## Einstellungen als Fenster über allem (aus dem Hauptmenü und aus dem Pausenmenü):
## Musik- und Effektlautstärke, Vibration, Größe und Seite der Touch-Knöpfe, Geist, Intro, Spielername.

signal closed



## Fenster öffnen (parent: ein Bildschirm oder eine CanvasLayer)
static func open(parent: Node) -> SettingsPanel:
	var p := SettingsPanel.new()
	parent.add_child(p)
	p._build()
	return p


func _build() -> void:
	UI.screen(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var left := -(UI.vw() - 960.0) / 2.0
	UI.rect(self, Rect2(left, 0, UI.vw(), 540), Color(0.02, 0.025, 0.06, 0.8))
	var p := UI.panel(self, Rect2(200, 24, 560, 492), UI.YELLOW)
	UI.image(p, "icon-gear", Vector2(36, 34), 2.4).modulate = UI.YELLOW
	UI.label(p, "Einstellungen", Vector2(60, 24), 16, UI.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 400)
	var close := UI.icon_button(p, "icon-close", Vector2(520, 34), _close, 44, 2.0)
	close.focus_mode = Control.FOCUS_NONE
	var s: Dictionary = Save.data["settings"]
	var y := 82.0
	y = _slider(p, y, "Musik", "music")
	y = _slider(p, y, "Effekte", "sfx")
	y = _choice(p, y, "Größe der Touch-Knöpfe", "touch_size", [["Klein", 0.85], ["Mittel", 1.0], ["Groß", 1.2]])
	y = _toggle(p, y, "Linkshänder (Knöpfe links, Stick rechts)", "lefty")
	y = _toggle(p, y, "Vibration bei Treffern", "vibration")
	y = _toggle(p, y, "Geist der Bestzeit anzeigen", "ghost")
	y = _toggle(p, y, "Intro beim Start", "intro")
	# Spielername für die Rangliste (zufällig, keine freie Eingabe)
	UI.rect(p, Rect2(24, y + 4, 512, 2), UI.LINE)
	UI.label(p, "Name in der Rangliste", Vector2(28, y + 22), 8, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 300)
	var name_label := UI.label(p, Names.current(), Vector2(28, y + 40), 11, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 330)
	var b := UI.button(p, "Neuer Name", Vector2(460, y + 40), func():
		Save.data["player_name"] = Names.random()
		Save.persist()
		name_label.text = Names.current(), 140, 40)
	b.add_theme_font_size_override("font_size", 9)


func _slider(p: Control, y: float, text: String, key: String) -> float:
	UI.label(p, text, Vector2(28, y + 8), 10, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 200)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = float(Save.data["settings"].get(key, 1.0))
	p.add_child(sl)
	sl.position = Vector2(200, y)
	sl.size = Vector2(280, 32)
	var pct := UI.label(p, "%d %%" % roundi(sl.value * 100), Vector2(536, y + 9), 8, UI.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 60)
	sl.value_changed.connect(func(v: float):
		Save.data["settings"][key] = v
		pct.text = "%d %%" % roundi(v * 100)
		Music.refresh_volume()
		if key == "sfx":
			Sfx.play("leaf"))
	sl.drag_ended.connect(func(_c): Save.persist())
	return y + 48


func _choice(p: Control, y: float, text: String, key: String, options: Array) -> float:
	UI.label(p, text, Vector2(28, y + 10), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 240)
	var buttons: Array[Button] = []
	var w := 88.0
	for i in options.size():
		var b := UI.button(p, options[i][0], Vector2(536 - (options.size() - i) * (w + 4) + w / 2, y + 16), func(): pass, w, 34)
		b.add_theme_font_size_override("font_size", 8)
		b.focus_mode = Control.FOCUS_NONE
		buttons.append(b)
	var refresh := func():
		for i in buttons.size():
			var on: bool = is_equal_approx(float(Save.data["settings"].get(key, 1.0)), float(options[i][1]))
			buttons[i].add_theme_stylebox_override("normal", UI.box(UI.YELLOW if on else UI.PANEL_LIGHT, 10, 2, UI.YELLOW if on else UI.LINE))
			buttons[i].add_theme_color_override("font_color", UI.INK if on else UI.MUTED)
	for i in buttons.size():
		buttons[i].pressed.connect(func():
			Save.data["settings"][key] = options[i][1]
			Save.persist()
			refresh.call())
	refresh.call()
	return y + 50


func _toggle(p: Control, y: float, text: String, key: String) -> float:
	UI.label(p, text, Vector2(28, y + 10), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 400)
	var b := UI.button(p, "", Vector2(496, y + 16), func(): pass, 80, 32)
	b.add_theme_font_size_override("font_size", 8)
	b.focus_mode = Control.FOCUS_NONE
	var refresh := func():
		var on: bool = Save.data["settings"].get(key, false)
		b.text = "AN" if on else "AUS"
		b.add_theme_stylebox_override("normal", UI.box(UI.GREEN.darkened(0.35) if on else UI.PANEL_LIGHT, 16, 2, UI.GREEN if on else UI.LINE))
		b.add_theme_stylebox_override("hover", UI.box(UI.GREEN.darkened(0.2) if on else Color("#262c5a"), 16, 2, UI.GREEN if on else Color("#4a5394")))
		b.add_theme_color_override("font_color", Color.WHITE if on else UI.MUTED)
	b.pressed.connect(func():
		Save.data["settings"][key] = not Save.data["settings"].get(key, false)
		Save.persist()
		refresh.call())
	refresh.call()
	return y + 44


func _close() -> void:
	Save.persist()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		_close()
