class_name PauseMenu
extends Control
## Pausenmenü: Weiter, Neu starten, Schulplan, Ton. Läuft auch, während das Spiel angehalten ist.

signal resume
signal restart
signal quit_to_map
signal quit_to_menu
signal settings_requested

var _sound: Button


func build(level_text: String, char_name: String, difficulty: String) -> void:
	UI.screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var left := -(UI.vw() - 960.0) / 2.0
	UI.rect(self, Rect2(left, 0, UI.vw(), 540), Color(0.02, 0.025, 0.06, 0.72))
	var p := UI.panel(self, Rect2(300, 40, 360, 460), UI.YELLOW)
	UI.label(p, "PAUSE", Vector2(180, 24), 20, UI.YELLOW)
	UI.label(p, level_text, Vector2(180, 58), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 340)
	UI.label(p, "%s · %s" % [char_name, difficulty], Vector2(180, 78), 7, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 340)
	var go := UI.primary(p, "Weiter", Vector2(180, 136), func(): resume.emit(), 280, 58)
	var rows := [["Neu starten", "icon-restart", func(): restart.emit()], ["Schulplan", "icon-map", func(): quit_to_map.emit()],
		["Hauptmenü", "icon-home", func(): quit_to_menu.emit()]]
	for i in rows.size():
		var b := UI.button(p, rows[i][0], Vector2(180, 200 + i * 56), rows[i][2], 280, 46)
		UI.image(b, rows[i][1], Vector2(30, 23), 2.0)
	_sound = UI.button(p, "", Vector2(180, 368), _toggle_sound, 280, 46)
	_show_sound()
	var settings := UI.button(p, "Einstellungen", Vector2(180, 424), func(): settings_requested.emit(), 280, 46)
	UI.image(settings, "icon-gear", Vector2(30, 23), 2.0)
	go.grab_focus.call_deferred()


func _toggle_sound() -> void:
	Sfx.toggle_mute()
	_show_sound()


func _show_sound() -> void:
	var muted: bool = Save.data["muted"]
	_sound.text = "Ton: aus" if muted else "Ton: an"
	for c in _sound.get_children():
		c.queue_free()
	UI.image(_sound, "icon-mute" if muted else "icon-sound", Vector2(30, 23), 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		resume.emit()
