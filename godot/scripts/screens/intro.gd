extends Control
## Kurzes Intro beim Spielstart: „an evolvimus production“ und „by Nikola Kostic“.
## Ein Tipp, Klick oder eine Taste überspringt es.

var params := {}
var _done := false
var _root: Control


func _ready() -> void:
	UI.screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var left := -(UI.vw() - 960.0) / 2.0
	UI.rect(self, Rect2(left, 0, UI.vw(), 540), Color("#05060d"))
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# --- Teil 1: Ginkgoblatt mit Lichtschein, dann „an EVOLVIMUS production“
	var glow := UI.glow(_root, Vector2(480, 178), 150, Color(1.0, 0.8, 0.2, 0.0))
	var leaf := UI.image(_root, "leaf", Vector2(480, 178), 5.0)
	leaf.pivot_offset = leaf.size / 2
	leaf.modulate.a = 0.0
	leaf.scale = Vector2(0.4, 0.4)
	leaf.rotation_degrees = -30

	var an := UI.label(_root, "an", Vector2(480, 262), 10, UI.MUTED)
	an.modulate.a = 0.0
	var word := "EVOLVIMUS"
	var letters: Array[Label] = []
	var spacing := 38.0
	for i in word.length():
		var l := UI.label(_root, word[i], Vector2(480 + (i - (word.length() - 1) / 2.0) * spacing, 290), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 40)
		l.modulate.a = 0.0
		letters.append(l)
	var prod := UI.label(_root, "P R O D U C T I O N", Vector2(480, 344), 10, UI.YELLOW)
	prod.modulate.a = 0.0
	var line := UI.rect(_root, Rect2(480, 334, 0, 2), UI.YELLOW)

	# --- Teil 2: „by Nikola Kostic“
	var by := UI.label(_root, "by", Vector2(480, 236), 10, UI.MUTED)
	by.modulate.a = 0.0
	var name_label := UI.label(_root, "Nikola Kostic", Vector2(480, 262), 20, Color.WHITE)
	name_label.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_callback(func(): Sfx.play("intro"))
	tw.set_parallel()
	tw.tween_property(leaf, "modulate:a", 1.0, 0.5)
	tw.tween_property(leaf, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(leaf, "rotation_degrees", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(glow, "modulate:a", 0.35, 0.9)
	tw.chain().tween_property(an, "modulate:a", 1.0, 0.3)
	for i in letters.size():
		var l := letters[i]
		var y := l.position.y
		l.position.y = y + 10
		tw.chain().tween_callback(func(): Sfx.play("tick", 1.0 + i * 0.07))
		tw.tween_property(l, "modulate:a", 1.0, 0.16)
		tw.tween_property(l, "position:y", y, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(line, "position:x", 330.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(line, "size:x", 300.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(prod, "modulate:a", 1.0, 0.5)
	tw.chain().tween_interval(1.1)
	# Teil 1 ausblenden
	var part1: Array[CanvasItem] = [an, prod, line, leaf, glow]
	part1.append_array(letters)
	tw.chain().tween_property(part1[0], "modulate:a", 0.0, 0.45)
	for n in part1.slice(1):
		tw.tween_property(n, "modulate:a", 0.0, 0.45)
	tw.chain().tween_interval(0.15)
	tw.chain().tween_property(by, "modulate:a", 1.0, 0.45)
	tw.tween_property(name_label, "modulate:a", 1.0, 0.6)
	tw.chain().tween_interval(1.4)
	tw.chain().tween_property(by, "modulate:a", 0.0, 0.45)
	tw.tween_property(name_label, "modulate:a", 0.0, 0.45)
	tw.chain().tween_interval(0.2)
	tw.chain().tween_callback(_finish)

	UI.label(self, "Tippen zum Überspringen", Vector2(480, 506), 7, Color("#3a3f66"))


func _finish() -> void:
	if _done:
		return
	_done = true
	Nav.goto("menu")


func _gui_input(event: InputEvent) -> void:
	if UI.is_tap(event):
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		_finish()
