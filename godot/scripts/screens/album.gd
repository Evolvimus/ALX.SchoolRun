extends Control
## Sammelalbum: alle Figuren als Karten. Freigeschaltete können ausgewählt werden.

var params := {}
var _info: Label


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	UI.title(self, "Sammelalbum", 36)
	_info = UI.label(self, "", Vector2(560, 482), 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 760)
	_describe(Chars.get_char(Save.data["selected"]))
	var all := Chars.all
	var per_row := 11
	for i in all.size():
		var c: Dictionary = all[i]
		var x := 75 + (i % per_row) * 82.0
		var y := 150 + floorf(i / per_row) * 150.0
		var unlocked := Save.is_unlocked(c["id"])
		var card := UI.card(self, c, unlocked, Vector2(x, y), 0.7)
		if c["id"] == Save.data["selected"]:
			UI.rect(self, Rect2(x - 42, y - 56, 84, 112), Color.TRANSPARENT, 4, Color.WHITE)
		card.mouse_entered.connect(func(): if unlocked: _describe(c))
		card.mouse_exited.connect(func(): _describe(Chars.get_char(Save.data["selected"])))
		card.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT or e is InputEventScreenTouch and e.pressed:
				if not unlocked:
					var how := "per Karten-Code oder im Shop freischalten" if c["price"] > 0 else "nur per Karten-Code"
					_info.text = "Gesperrt · %s – %s" % [Chars.RARITY_LABEL[c["rarity"]], how]
					return
				Sfx.play("click")
				Save.data["selected"] = c["id"]
				Save.persist()
				Nav.goto("album"))
	UI.back_button(self)


func _describe(c: Dictionary) -> void:
	_info.text = "%s (%s) · %s\nFähigkeit: %s" % [c["name"], c["subject"], Chars.RARITY_LABEL[c["rarity"]], Chars.ability_text(c)]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
