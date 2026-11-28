extends Control
## Karten-Code einlösen: links Eingabe, rechts erscheint die freigeschaltete Karte.

var params := {}
var _edit: LineEdit
var _msg: Label
var _busy := false
var _card: Control
var _slot: Control


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	UI.top_bar(self, "Code einlösen")

	var p := UI.panel(self, Rect2(60, 104, 500, 380))
	UI.image(p, "icon-code", Vector2(250, 52), 4.0)
	UI.label(p, "Dein Karten-Code", Vector2(250, 94), 13, Color.WHITE)
	UI.para(p, "Er steht auf der Rückseite deiner ALX-Sammelkarte. Jeder Code klappt nur ein einziges Mal.", Vector2(40, 120), 420, 8, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_edit = LineEdit.new()
	_edit.placeholder_text = "ALX-XXXX-XXXX"
	_edit.max_length = 14
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	_edit.text_submitted.connect(func(_t): _submit())
	_edit.text_changed.connect(func(t: String):
		var col := _edit.caret_column
		_edit.text = t.to_upper()
		_edit.caret_column = col)
	p.add_child(_edit)
	_edit.position = Vector2(60, 176)
	_edit.size = Vector2(380, 64)
	UI.primary(p, "Einlösen", Vector2(250, 290), _submit, 380, 64)
	_msg = UI.label(p, "", Vector2(250, 334), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 460)
	if Backend.test_mode:
		UI.label(self, "TESTMODUS · Testcodes: ALX-HAMM-ER2N (Herr Hammer) · ALX-MYTH-HAYH (Admin Hammer)", Vector2(480, 508), 7, Color("#a05a6a"), HORIZONTAL_ALIGNMENT_CENTER, 900)

	# Platz für die Karte: Rückseite mit Fragezeichen, bis ein Code eingelöst ist
	_slot = UI.panel(self, Rect2(640, 134, 220, 300), UI.LINE, Color(0.06, 0.07, 0.15, 0.85))
	UI.image(_slot, "leaf", Vector2(110, 120), 4.0).modulate = Color(1, 1, 1, 0.15)
	UI.label(_slot, "?", Vector2(110, 196), 28, UI.DIM)
	var bob := _slot.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	bob.tween_property(_slot, "position:y", 126.0, 1.4)
	bob.tween_property(_slot, "position:y", 134.0, 1.4)
	if not Nav.touch_enabled():
		_edit.grab_focus.call_deferred()
	if Nav.args.has("code"):  # Startoption für automatische Tests
		_edit.text = Nav.args["code"]
		_submit()


func _message(text: String, color: Color) -> void:
	_msg.add_theme_color_override("font_color", color)
	_msg.text = text


func _submit() -> void:
	if _busy:
		return
	var code := CodeFormat.validate(_edit.text)
	if code == "":
		_message("Ungültiger Code – bitte nochmal genau abtippen.", UI.RED)
		_shake(_edit)
		return
	_busy = true
	_message("Wird geprüft …", UI.MUTED)
	var res: Dictionary = await Backend.redeem(code)
	_busy = false
	if not res["ok"]:
		_message({ "used": "Dieser Code wurde schon eingelöst.", "invalid": "Diesen Code gibt es nicht." }.get(res["reason"], "Keine Verbindung – versuche es später nochmal."), UI.RED)
		_shake(_edit)
		return
	var c := Chars.get_char(res["id"])
	Save.unlock(c["id"])
	Save.data["selected"] = c["id"]  # neue Figur ist sofort spielbar
	Save.persist()
	_edit.text = ""
	_edit.release_focus()
	if c["rarity"] == "mythisch":
		_message("MYTHISCH! %s ist freigeschaltet\nund ausgewählt." % c["name"], Color("#ff9fd0"))
		Sfx.play("magic")
	else:
		_message("%s ist freigeschaltet\nund ausgewählt." % c["name"], UI.GREEN)
		Sfx.play("win")
	_slot.visible = false
	if _card:
		_card.queue_free()
	var rc: Color = Art.col(Chars.RARITY_COLOR[c["rarity"]])
	UI.glow(self, Vector2(750, 284), 170, Color(rc, 0.4))
	_card = UI.card(self, c, true, Vector2(750, 284), 2.0)
	_card.pivot_offset = _card.size / 2
	_card.scale = Vector2(0.1, 0.1)
	var tw := _card.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.7)
	tw.tween_property(_card, "rotation", TAU, 0.7)


func _shake(n: Control) -> void:
	var x := n.position.x
	var tw := n.create_tween()
	for k in 4:
		tw.tween_property(n, "position:x", x + (8 if k % 2 == 0 else -8), 0.04)
	tw.tween_property(n, "position:x", x, 0.04)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
