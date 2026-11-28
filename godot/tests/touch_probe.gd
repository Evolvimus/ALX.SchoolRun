extends Node
## Test der Touch-Steuerung (Start mit --level=1 --touch --touch-probe --quit):
## Ein simulierter Finger schiebt den Stick nach rechts, dann wird der Sprung-Knopf gedrückt.
## Gibt TOUCH_RESULT mit Strecke und Sprunghöhe aus.

func _ready() -> void:
	await get_tree().create_timer(0.8).timeout
	var game: Node = Nav.current
	var p: Node2D = game.player
	var x0 := p.position.x
	var y0 := p.position.y
	var vw := UI.vw()
	_mouse(Vector2(150, 440), true)
	_move(Vector2(230, 440))
	await get_tree().create_timer(1.0).timeout
	var moved := p.position.x - x0
	_mouse(Vector2(230, 440), false)
	await get_tree().create_timer(0.3).timeout
	var x1 := p.position.x
	await get_tree().create_timer(0.3).timeout
	var coasted := p.position.x - x1
	# Sprung-Knopf (rechts unten); Mausfinger kann nur eins gleichzeitig
	var top := p.position.y
	_mouse(Vector2(vw - 96, 432), true)
	for i in 20:
		await get_tree().physics_frame
		top = minf(top, p.position.y)
	_mouse(Vector2(vw - 96, 432), false)
	await get_tree().create_timer(0.6).timeout
	print("TOUCH_RESULT moved=%.0f after_release=%.0f jump=%.0f" % [moved, coasted, y0 - top])
	get_tree().quit()


func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = _win(pos)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(e)


func _move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = _win(pos)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)


## Spielkoordinaten → Fensterkoordinaten (Eingaben kommen im Fenster an und werden umgerechnet)
func _win(pos: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * pos
