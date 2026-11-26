extends Control
## Karten-Code einlösen

var params := {}
var _edit: LineEdit
var _msg: Label
var _busy := false
var _card: Control


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	UI.title(self, "Karten-Code einlösen", 50)
	UI.label(self, "Den Code findest du auf der Rückseite deiner ALX-Sammelkarte.\nJeder Code funktioniert nur ein einziges Mal!", Vector2(480, 92), 10)
	_edit = LineEdit.new()
	_edit.placeholder_text = "ALX-XXXX-XXXX"
	_edit.max_length = 14
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.text_submitted.connect(func(_t): _submit())
	_edit.text_changed.connect(func(t: String):
		var col := _edit.caret_column
		_edit.text = t.to_upper()
		_edit.caret_column = col)
	add_child(_edit)
	_edit.position = Vector2(320, 150)
	_edit.size = Vector2(320, 54)
	UI.button(self, "Einlösen", Vector2(480, 246), _submit, 220, 50)
	_msg = UI.label(self, "", Vector2(480, 290), 12)
	if Backend.test_mode:
		UI.label(self, "TESTMODUS · Testcodes: ALX-HAMM-ER2N (Herr Hammer), ALX-MYTH-HAYH (Admin Hammer)", Vector2(565, 522), 8, Color("#ff9b9b"), HORIZONTAL_ALIGNMENT_CENTER, 760)
	UI.back_button(self)
	_edit.grab_focus.call_deferred()
	if Nav.args.has("code"):  # Startoption für automatische Tests
		_edit.text = Nav.args["code"]
		_submit()


func _submit() -> void:
	if _busy:
		return
	var code := CodeFormat.validate(_edit.text)
	if code == "":
		_msg.add_theme_color_override("font_color", Color("#ff7777"))
		_msg.text = "Ungültiger Code – bitte nochmal genau abtippen."
		return
	_busy = true
	_msg.add_theme_color_override("font_color", Color.WHITE)
	_msg.text = "Wird geprüft …"
	var res: Dictionary = await Backend.redeem(code)
	_busy = false
	if not res["ok"]:
		_msg.add_theme_color_override("font_color", Color("#ff7777"))
		_msg.text = { "used": "Dieser Code wurde schon eingelöst.", "invalid": "Diesen Code gibt es nicht." }.get(res["reason"], "Keine Verbindung – versuche es später nochmal.")
		return
	var c := Chars.get_char(res["id"])
	Save.unlock(c["id"])
	Save.data["selected"] = c["id"]  # neue Figur ist sofort spielbar
	Save.persist()
	_edit.text = ""
	if c["rarity"] == "mythisch":
		_msg.add_theme_color_override("font_color", Color("#ff7fbf"))
		_msg.text = "MYTHISCH! %s freigeschaltet!\nIst jetzt ausgewählt." % c["name"]
		Sfx.play("magic")
	else:
		_msg.add_theme_color_override("font_color", Color("#7dff7d"))
		_msg.text = "%s freigeschaltet!\nIst jetzt ausgewählt." % c["name"]
		Sfx.play("win")
	if _card:
		_card.queue_free()
	_card = UI.card(self, c, true, Vector2(480, 418))
	_card.pivot_offset = _card.size / 2
	_card.scale = Vector2(0.1, 0.1)
	var tw := _card.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.7)
	tw.tween_property(_card, "rotation", TAU, 0.7)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
