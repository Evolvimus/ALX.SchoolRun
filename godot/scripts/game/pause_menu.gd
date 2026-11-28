class_name PauseMenu
extends Control
## Pausenmenü: Weiter, Neu starten, Schulplan, Ton. Läuft auch, während das Spiel angehalten ist.

signal resume
signal restart
signal quit_to_map

var _sound: Button


func build(level_text: String, char_name: String, difficulty: String) -> void:
	UI.screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var left := -(UI.vw() - 960.0) / 2.0
	UI.rect(self, Rect2(left, 0, UI.vw(), 540), Color(0.02, 0.025, 0.06, 0.72))
	var p := UI.panel(self, Rect2(300, 70, 360, 400), UI.YELLOW)
	UI.label(p, "PAUSE", Vector2(180, 26), 20, UI.YELLOW)
	UI.label(p, level_text, Vector2(180, 62), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 340)
	UI.label(p, "%s · %s" % [char_name, difficulty], Vector2(180, 82), 7, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 340)
	var go := UI.primary(p, "Weiter", Vector2(180, 144), func(): resume.emit(), 280, 60)
	var again := UI.button(p, "Neu starten", Vector2(180, 214), func(): restart.emit(), 280, 50)
	UI.image(again, "icon-restart", Vector2(30, 25), 2.0)
	var map := UI.button(p, "Schulplan", Vector2(180, 274), func(): quit_to_map.emit(), 280, 50)
	UI.image(map, "icon-map", Vector2(30, 25), 2.0)
	_sound = UI.button(p, "", Vector2(180, 334), _toggle_sound, 280, 50)
	_show_sound()
	go.grab_focus.call_deferred()


func _toggle_sound() -> void:
	Sfx.toggle_mute()
	_show_sound()


func _show_sound() -> void:
	var muted: bool = Save.data["muted"]
	_sound.text = "Ton: aus" if muted else "Ton: an"
	for c in _sound.get_children():
		c.queue_free()
	UI.image(_sound, "icon-mute" if muted else "icon-sound", Vector2(30, 25), 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		resume.emit()
