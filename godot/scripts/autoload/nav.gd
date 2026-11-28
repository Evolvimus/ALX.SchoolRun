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
##   --difficulty=X entspannt, normal oder abi
##   --touch        Touch-Steuerung auch am PC zeigen
##   --build-levels Kachelsatz und fehlende Levelszenen aus tools/level_seeds.gd erzeugen (--force überschreibt)
##   --screen=NAME  direkt einen Bildschirm öffnen (menu, levels, album, redeem, shop, lexikon)
##   --code=CODE    im Code-Bildschirm diesen Code sofort einlösen
##   --pause-test   im Spiel nach 1 s das Pausenmenü öffnen (für Bildschirmfotos)
##   --touch-probe  Touch-Steuerung automatisch testen (mit --level=1 --touch, siehe tests/touch_probe.gd)
##   --daily        mit --level: als Tagesaufgabe spielen (heutige Zusatzregel)
##   --no-intro     ohne Intro direkt ins Menü
##   --shot=DATEI   nach --shot-after Millisekunden (Standard 1500) ein Bildschirmfoto speichern und beenden

const SCREENS := {
	"intro": "res://scripts/screens/intro.gd",
	"menu": "res://scripts/screens/menu.gd",
	"levels": "res://scripts/screens/level_select.gd",
	"album": "res://scripts/screens/album.gd",
	"redeem": "res://scripts/screens/redeem.gd",
	"shop": "res://scripts/screens/shop.gd",
	"lexikon": "res://scripts/screens/lexikon.gd",
	"rangliste": "res://scripts/screens/leaderboard.gd",
	"erfolge": "res://scripts/screens/achievements_screen.gd",
	"einstellungen": "res://scripts/screens/settings_screen.gd",
	"game": "res://scripts/game/game.gd",
}

var current: Node
var current_name := ""
var args := {}
var _params := {}
var _fade: ColorRect
var _resize_timer := Timer.new()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else true
	_setup_input()
	process_mode = Node.PROCESS_MODE_ALWAYS
	Sfx.process_mode = Node.PROCESS_MODE_ALWAYS  # Klicks auch im Pausenmenü
	get_tree().root.size_changed.connect(func(): _resize_timer.start())
	_resize_timer.one_shot = true
	_resize_timer.wait_time = 0.25
	_resize_timer.timeout.connect(_on_resized)
	add_child(_resize_timer)
	if args.has("build-levels"):
		LevelBuilder.run(args.has("force"), str(args.get("only", "")))
		get_tree().quit.call_deferred()
		return
	Levels.load_all()
	if args.has("unlock-all"):
		for c in Chars.all:
			Save.unlock(c["id"])
	if args.has("char"):
		Save.data["selected"] = args["char"]
	if args.has("difficulty"):
		Save.data["difficulty"] = args["difficulty"]


func start() -> void:
	if args.has("build-levels"):
		return
	if args.has("shot"):
		_screenshot_later()
	if args.has("touch-probe"):
		add_child.call_deferred(load("res://tests/touch_probe.gd").new())
	if args.has("screen"):
		goto(args["screen"])
	elif args.has("level"):
		goto("game", { "level": int(args["level"]), "daily": args.has("daily") })
	elif args.has("no-intro") or args.has("quit") or args.has("bot") or not Save.data["settings"].get("intro", true):
		goto("menu")
	else:
		goto("intro")


## Bildschirm wechseln, mit kurzer Abblende (bei Tests ohne).
func goto(screen: String, params := {}) -> void:
	get_tree().paused = false
	if current == null or args.has("shot") or args.has("bot") or args.has("quit"):
		_swap(screen, params)
		return
	if _fade == null:
		var layer := CanvasLayer.new()
		layer.layer = 100
		layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(layer)
		_fade = ColorRect.new()
		_fade.color = Color("#05060d")
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_fade)
	_fade.size = Vector2(UI.vw() + 10, 560)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := _fade.create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.12).from(0.0)
	tw.tween_callback(_swap.bind(screen, params))
	tw.tween_property(_fade, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _swap(screen: String, params: Dictionary) -> void:
	if current:
		current.queue_free()
	current = load(SCREENS[screen]).new()
	current.process_mode = Node.PROCESS_MODE_PAUSABLE  # Nav selbst läuft immer, die Bildschirme pausieren
	current_name = screen
	_params = params
	current.set("params", params)
	add_child(current)
	if screen == "intro":
		Music.play("")
	elif screen != "game":
		Music.play("menu")


## Kurze Einblendung oben rechts, die Bildschirmwechsel überlebt (Erfolge, Belohnungen)
var _toast_queue: Array = []
var _toast_layer: CanvasLayer


func toast(icon: String, title: String, text: String) -> void:
	_toast_queue.append([icon, title, text])
	if _toast_queue.size() == 1:
		_show_toast()


func _show_toast() -> void:
	if _toast_queue.is_empty():
		return
	var t: Array = _toast_queue[0]
	if _toast_layer == null:
		_toast_layer = CanvasLayer.new()
		_toast_layer.layer = 90
		_toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_toast_layer)
	var vw := UI.vw()
	var right := vw - UI.safe_insets().y - 16
	var box := UI.panel(_toast_layer, Rect2(vw + 20, 84, 320, 62), UI.YELLOW)
	box.theme = UI.theme()
	UI.fit(box, t[0], Vector2(36, 31), Vector2(36, 36)).modulate = UI.YELLOW if t[0] == "icon-trophy" else Color.WHITE
	UI.label(box, t[1], Vector2(68, 14), 7, UI.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 240)
	var l := UI.label(box, t[2], Vector2(68, 31), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 240)
	l.clip_text = true
	Sfx.play("magic")
	var tw := box.create_tween()
	tw.tween_property(box, "position:x", right - 320, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.6)
	tw.tween_property(box, "position:x", vw + 20, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		box.queue_free()
		_toast_queue.pop_front()
		_show_toast())


## Fenstergröße geändert (PC): Menüs neu aufbauen, damit sie mittig bleiben
func _on_resized() -> void:
	if current and current_name != "game" and current_name != "intro":
		_swap(current_name, _params)


func touch_enabled() -> bool:
	return args.has("touch") or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_LEFT, KEY_A], "move_right": [KEY_RIGHT, KEY_D],
		"move_up": [KEY_UP, KEY_W], "move_down": [KEY_DOWN, KEY_S],
		"jump": [KEY_SPACE], "attack": [KEY_X, KEY_J],
		"back": [KEY_ESCAPE], "mute": [KEY_M],
	}
	var pads := {
		"move_left": [JOY_BUTTON_DPAD_LEFT], "move_right": [JOY_BUTTON_DPAD_RIGHT],
		"move_up": [JOY_BUTTON_DPAD_UP], "move_down": [JOY_BUTTON_DPAD_DOWN],
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
	for pair in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0], ["move_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)


func _screenshot_later() -> void:
	await get_tree().create_timer(int(args.get("shot-after", 1500)) / 1000.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args["shot"])
	print("SCREENSHOT ", args["shot"])
	get_tree().quit()
