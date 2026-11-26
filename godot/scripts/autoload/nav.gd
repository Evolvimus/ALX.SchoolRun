extends Node
## Wechselt zwischen den Bildschirmen (Menü, Levelauswahl, Spiel …) und legt die Steuerung fest.
##
## Startoptionen für Tests (nach "--" angeben, z. B. godot --path . -- --level=2 --bot):
##   --level=N      startet direkt Level N (0 = Tutorial)
##   --bot          ein Testbot spielt das Level
##   --quit         nach Levelende beenden und Ergebnis ausgeben
##   --fresh        leerer Spielstand, nichts wird gespeichert
##   --unlock-all   alle Figuren freischalten
##   --char=ID      mit dieser Figur spielen
##   --touch        Touch-Steuerung auch am PC zeigen
##   --screen=NAME  direkt einen Bildschirm öffnen (menu, levels, album, redeem, shop, lexikon)
##   --code=CODE    im Code-Bildschirm diesen Code sofort einlösen
##   --shot=DATEI   nach --shot-after Millisekunden (Standard 1500) ein Bildschirmfoto speichern und beenden

const SCREENS := {
	"menu": "res://scripts/screens/menu.gd",
	"levels": "res://scripts/screens/level_select.gd",
	"album": "res://scripts/screens/album.gd",
	"redeem": "res://scripts/screens/redeem.gd",
	"shop": "res://scripts/screens/shop.gd",
	"lexikon": "res://scripts/screens/lexikon.gd",
	"game": "res://scripts/game/game.gd",
}

var current: Node
var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else true
	_setup_input()
	if args.has("unlock-all"):
		for c in Chars.all:
			Save.unlock(c["id"])
	if args.has("char"):
		Save.data["selected"] = args["char"]


func start() -> void:
	if args.has("shot"):
		_screenshot_later()
	if args.has("screen"):
		goto(args["screen"])
	elif args.has("level"):
		goto("game", { "level": int(args["level"]) })
	else:
		goto("menu")


func goto(screen: String, params := {}) -> void:
	if current:
		current.queue_free()
	current = load(SCREENS[screen]).new()
	current.set("params", params)
	add_child(current)


func touch_enabled() -> bool:
	return args.has("touch") or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_LEFT, KEY_A], "move_right": [KEY_RIGHT, KEY_D],
		"jump": [KEY_SPACE, KEY_UP, KEY_W], "attack": [KEY_X, KEY_J],
		"back": [KEY_ESCAPE], "mute": [KEY_M],
	}
	var pads := {
		"move_left": [JOY_BUTTON_DPAD_LEFT], "move_right": [JOY_BUTTON_DPAD_RIGHT],
		"jump": [JOY_BUTTON_A], "attack": [JOY_BUTTON_X, JOY_BUTTON_B], "back": [JOY_BUTTON_START],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		for b in pads.get(action, []):
			var j := InputEventJoypadButton.new()
			j.button_index = b
			InputMap.action_add_event(action, j)
	for pair in [["move_left", -1.0], ["move_right", 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = pair[1]
		InputMap.action_add_event(pair[0], m)


func _screenshot_later() -> void:
	await get_tree().create_timer(int(args.get("shot-after", 1500)) / 1000.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args["shot"])
	print("SCREENSHOT ", args["shot"])
	get_tree().quit()
