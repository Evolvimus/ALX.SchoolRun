extends Control
## Erfolge und Sammel-Belohnungen auf einen Blick.

var params := {}


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	var got := 0
	for a in Achievements.LIST:
		if Achievements.has(a["id"]):
			got += 1
	var right := UI.top_bar(self, "Erfolge")
	UI.chip(self, "icon-trophy", "%d/%d" % [got, Achievements.LIST.size()], right, 40, UI.YELLOW, 10)

	# Sammel-Belohnungen oben als Fortschrittsleiste
	var teachers := Achievements._teachers()
	var bar := UI.panel(self, Rect2(24, 80, 912, 84))
	UI.label(bar, "SAMMEL-BELOHNUNGEN", Vector2(20, 14), 8, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 300)
	UI.label(bar, "%d von %d Lehrern" % [teachers, Chars.teachers.size()], Vector2(892, 14), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 300)
	var x0 := 20.0
	var w := 872.0
	UI.rect(bar, Rect2(x0, 40, w, 10), Color("#0b0d1f"), 2, UI.LINE, 5)
	UI.rect(bar, Rect2(x0, 40, w * minf(1.0, teachers / 20.0), 10), UI.YELLOW, 0, Color.TRANSPARENT, 5)
	for st in Rewards.STEPS:
		var sx: float = x0 + w * st["need"] / 20.0
		var done := Rewards.has(st["id"])
		var dot := UI.rect(bar, Rect2(sx - 12, 33, 24, 24), UI.YELLOW if done else Color("#1d2246"), 2, UI.YELLOW if done else UI.LINE, 12)
		UI.label(dot, str(st["need"]), Vector2(12, 7), 7, UI.INK if done else UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 24)
		UI.label(bar, st["name"], Vector2(minf(sx, 820), 62), 7, UI.YELLOW if done else UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 220)

	# Erfolge als Kacheln (4 Spalten)
	var cols := 4
	var tw := (912.0 - (cols - 1) * 10) / cols
	var th := 64.0
	for i in Achievements.LIST.size():
		var a: Dictionary = Achievements.LIST[i]
		var have := Achievements.has(a["id"])
		var r := Rect2(24 + (i % cols) * (tw + 10), 176 + (i / cols) * (th + 8), tw, th)
		var tile := UI.panel(self, r, UI.YELLOW if have else UI.LINE, Color(0.1, 0.1, 0.2, 0.92) if have else Color(0.05, 0.06, 0.13, 0.85))
		var icon := UI.image(tile, "icon-trophy", Vector2(28, th / 2), 2.4)
		icon.modulate = UI.YELLOW if have else UI.DIM
		UI.label(tile, a["name"], Vector2(52, 14), 7, Color.WHITE if have else UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, tw - 60)
		var t := UI.para(tile, a["text"], Vector2(52, 32), tw - 60, 6, UI.MUTED if have else UI.DIM)
		t.add_theme_constant_override("line_spacing", 4)
		UI.pop_in(tile, 0.015 * i, 6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
