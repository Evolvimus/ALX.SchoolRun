extends Control
## Lehrerzimmer-Shop: nach Ende der Kartenaktion Lehrer mit Ginkgo-Talern freischalten (kein Echtgeld).

var params := {}
var _info: Label


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	UI.title(self, "Lehrerzimmer-Shop", 36)
	UI.label(self, "%d Ginkgo-Taler" % Save.data["coins"], Vector2(940, 20), 14, Color("#ffd700"), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	UI.back_button(self)
	var loading := UI.label(self, "Lade …", Vector2(480, 260), 16)
	var open: bool = await Backend.shop_open()
	loading.queue_free()
	if not open:
		UI.label(self, "Der Shop öffnet nach dem Ende der Sammelkartenaktion.\nBis dahin: Karten sammeln und Codes einlösen!\n\nSammle schon mal Ginkgo-Taler in den Levels.", Vector2(480, 210), 13)
		return
	var locked := Chars.teachers.filter(func(t): return not Save.is_unlocked(t["id"]) and t["price"] > 0)
	if locked.is_empty():
		UI.label(self, "Du hast alle Lehrer!", Vector2(480, 250), 18)
		return
	_info = UI.label(self, "Kostenlos – nur mit im Spiel verdienten Ginkgo-Talern", Vector2(560, 490), 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 760)
	for i in locked.size():
		var t: Dictionary = locked[i]
		var x := 75 + (i % 11) * 82.0
		var y := 140 + floorf(i / 11.0) * 170.0
		var card := UI.card(self, t, false, Vector2(x, y), 0.7)
		UI.label(self, "%d" % t["price"], Vector2(x, y + 58), 9, Color("#ffd700"), HORIZONTAL_ALIGNMENT_CENTER, 80)
		card.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT or e is InputEventScreenTouch and e.pressed:
				var coins := int(Save.data["coins"])
				if coins < t["price"]:
					_info.text = "Dir fehlen noch %d Ginkgo-Taler." % (t["price"] - coins)
					return
				Save.data["coins"] = coins - t["price"]
				Save.unlock(t["id"])
				Sfx.play("win")
				Nav.goto("shop"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
