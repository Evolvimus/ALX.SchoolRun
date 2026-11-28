extends Control
## Figuren (Sammelalbum): links die große Vorschau der angetippten Figur, rechts alle Karten.
## Im Shop-Modus (shop.gd) stehen nur kaufbare Lehrer im Raster, der Button kauft mit Ginkgo-Talern.

var params := {}
var shop := false
var _chars: Array = []
var _cards: Array[Panel] = []
var _focus := 0
var _detail: Control
var _coins_chip: PanelContainer
var _shop_open := false

const COLS := 7
const GAP := Vector2(9, 10)
var CARD := Vector2(76, 112)


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	var right := UI.top_bar(self, "Lehrerzimmer-Shop" if shop else "Figuren")
	_coins_chip = UI.chip(self, "icon-coin", "%d" % Save.data["coins"], right, 40, Color("#ffd23f"), 12)
	if shop:
		var loading := UI.label(self, "Lade …", Vector2(480, 260), 12, UI.MUTED)
		_shop_open = await Backend.shop_open()
		loading.queue_free()
		if not _shop_open:
			_closed()
			return
		_chars = Chars.teachers.filter(func(t): return not Save.is_unlocked(t["id"]) and t["price"] > 0)
		if _chars.is_empty():
			var p := UI.panel(self, Rect2(250, 170, 460, 180))
			UI.image(p, "icon-star", Vector2(230, 56), 4.0).modulate = UI.YELLOW
			UI.label(p, "Du hast alle Lehrer!", Vector2(230, 100), 14)
			UI.label(p, "Stark. Mehr gibt es hier gerade nicht.", Vector2(230, 130), 8, UI.MUTED)
			return
	else:
		_chars = Chars.all.duplicate()
		var count := 0
		for c in _chars:
			if Save.is_unlocked(c["id"]):
				count += 1
		UI.chip(self, "icon-card", "%d/%d" % [count, _chars.size()], _coins_chip.position.x - 10, 40, UI.TEXT, 12)
	_build_grid()
	var start := 0
	for i in _chars.size():
		if _chars[i]["id"] == Save.data["selected"]:
			start = i
	_show(start)


func _closed() -> void:
	var p := UI.panel(self, Rect2(220, 140, 520, 260))
	UI.image(p, "icon-shop", Vector2(260, 60), 4.0)
	UI.label(p, "Der Shop hat noch zu", Vector2(260, 104), 14, UI.YELLOW)
	UI.para(p, "Er öffnet nach dem Ende der Sammelkarten-Aktion. Bis dahin: Karten sammeln und Codes einlösen!", Vector2(40, 140), 440, 8, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	UI.para(p, "Ginkgo-Taler sammelst du schon jetzt in jedem Level – ganz ohne Echtgeld.", Vector2(40, 200), 440, 8, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_CENTER)


func _build_grid() -> void:
	var rows := ceili(_chars.size() / float(COLS))
	CARD.y = minf(112.0, floorf((436.0 - (rows - 1) * GAP.y) / rows))
	var x0 := 960 - 24 - COLS * CARD.x - (COLS - 1) * GAP.x
	for i in _chars.size():
		var c: Dictionary = _chars[i]
		var col := i % COLS
		var row := i / COLS
		var center := Vector2(x0 + col * (CARD.x + GAP.x) + CARD.x / 2, 84 + row * (CARD.y + GAP.y) + CARD.y / 2)
		var unlocked := Save.is_unlocked(c["id"])
		var card := UI.card(self, c, unlocked or shop, center, CARD.x / 110.0)
		card.size.y = CARD.y
		card.position.y = center.y - CARD.y / 2
		if shop:
			var txt := "%d" % c["price"]
			var w := txt.length() * 7 + 13
			UI.image(card, "icon-coin", Vector2((CARD.x - w) / 2 + 4.5, CARD.y - 11), 1.0)
			UI.label(card, txt, Vector2((CARD.x - w) / 2 + 13, CARD.y - 15), 7, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_LEFT, 60)
		if c["id"] == Save.data["selected"] and not shop:
			var badge := UI.rect(card, Rect2(CARD.x - 24, 4, 20, 20), Color("#1f8a3a"), 0, Color.TRANSPARENT, 10)
			UI.image(badge, "check", Vector2(10, 10), 1.4).modulate = Color.WHITE
		card.gui_input.connect(func(e: InputEvent):
			if UI.is_tap(e):
				Sfx.play("click")
				_show(i))
		_cards.append(card)
		UI.pop_in(card, 0.012 * i, 8)


func _show(i: int) -> void:
	_focus = i
	for k in _cards.size():
		_cards[k].modulate = Color.WHITE
		var s := (_cards[k].get_theme_stylebox("panel") as StyleBoxFlat)
		s.shadow_size = 0
	var cs := (_cards[i].get_theme_stylebox("panel") as StyleBoxFlat)
	cs.shadow_color = Color(1, 1, 1, 0.55)
	cs.shadow_size = 4
	cs.shadow_offset = Vector2.ZERO
	if _detail:
		_detail.queue_free()
	var c: Dictionary = _chars[i]
	var unlocked := Save.is_unlocked(c["id"])
	var rc: Color = Art.col(Chars.RARITY_COLOR[c["rarity"]])
	_detail = UI.panel(self, Rect2(24, 84, 312, 436), rc if unlocked or shop else UI.LINE)
	var d := _detail
	# Bühne mit Figur
	UI.glow(d, Vector2(156, 120), 110, Color(rc, 0.35 if unlocked or shop else 0.1))
	var fig := UI.image(d, "char-" + c["id"], Vector2(156, 100), Chars.display_scale(c) * 1.25)
	fig.position.y = 200 - fig.size.y
	if not (unlocked or shop):
		fig.modulate = Color(0.03, 0.035, 0.08)
		UI.image(d, "icon-lock", Vector2(156, 130), 3.0).modulate = Color(rc, 0.8)
	var known := unlocked or shop
	UI.label(d, c["name"] if known else "???", Vector2(156, 214), 13, Color.WHITE)
	UI.label(d, c["subject"] if known else "Noch nicht freigeschaltet", Vector2(156, 236), 8, UI.MUTED)
	var tg := UI.tag(d, Chars.RARITY_LABEL[c["rarity"]].to_upper(), Vector2.ZERO, rc, 7)
	tg.position = Vector2(156 - tg.size.x / 2, 256)
	UI.rect(d, Rect2(24, 290, 264, 2), UI.LINE)
	UI.label(d, "Fähigkeit", Vector2(24, 304), 8, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 264)
	UI.para(d, Chars.ability_text(c) if known else "???", Vector2(24, 320), 264, 8, Color.WHITE)
	if unlocked and not shop:
		Skins.attach_rect(fig, c["id"])
		_hat_row(d)
	# Aktion
	if shop:
		var price := int(c["price"])
		var coins := int(Save.data["coins"])
		var buy := UI.primary(d, "Kaufen  %d" % price, Vector2(156, 398), func(): _buy(c), 264, 56)
		buy.add_theme_font_size_override("font_size", 12)
		if coins < price:
			buy.disabled = true
			UI.label(d, "Dir fehlen noch %d Taler" % (price - coins), Vector2(156, 360), 7, UI.RED)
	elif not unlocked:
		var how := "Code von der Sammelkarte einlösen" + (" oder im Shop kaufen" if c["price"] > 0 else "")
		UI.para(d, how, Vector2(24, 366), 264, 7, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		UI.button(d, "Code einlösen", Vector2(156, 410), func(): Nav.goto("redeem"), 264, 48)
	elif c["id"] == Save.data["selected"]:
		var b := UI.button(d, "Ausgewählt", Vector2(156, 398), func(): pass, 264, 56)
		b.disabled = true
		UI.image(b, "check", Vector2(40, 28), 2.0)
	else:
		UI.primary(d, "Auswählen", Vector2(156, 398), func(): _choose(c), 264, 56)


## Event-Hüte (gelten für alle Figuren)
func _hat_row(d: Control) -> void:
	var owned := Skins.owned()
	if owned.is_empty():
		return
	UI.label(d, "Hut", Vector2(24, 352), 7, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 60)
	var options: Array = [""] + owned
	for i in options.size():
		var id: String = options[i]
		var on: bool = Save.data["skin"] == id
		var b := UI.button(d, "", Vector2(80 + i * 38, 358), func():
			Save.data["skin"] = id
			Save.persist()
			Sfx.play("click")
			_show(_focus), 32, 28)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", UI.box(UI.YELLOW if on else UI.PANEL_LIGHT, 8, 2, UI.YELLOW if on else UI.LINE, 2))
		if id == "":
			UI.image(b, "icon-close", Vector2(16, 14), 1.0).modulate = UI.INK if on else UI.MUTED
		else:
			UI.fit(b, "acc-" + id, Vector2(16, 14), Vector2(22, 20))


func _choose(c: Dictionary) -> void:
	Save.data["selected"] = c["id"]
	Save.persist()
	Sfx.play("checkpoint")
	Nav.goto("album")


func _buy(c: Dictionary) -> void:
	var coins := int(Save.data["coins"])
	if coins < c["price"]:
		return
	Save.data["coins"] = coins - c["price"]
	Save.unlock(c["id"])
	Save.data["selected"] = c["id"]
	Save.persist()
	Sfx.play("win")
	Nav.goto("shop")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
		return
	if _cards.is_empty():
		return
	var step := 0
	if event.is_action_pressed("move_right"): step = 1
	elif event.is_action_pressed("move_left"): step = -1
	elif event.is_action_pressed("move_down"): step = COLS
	elif event.is_action_pressed("move_up"): step = -COLS
	if step != 0:
		var j := _focus + step
		if j >= 0 and j < _cards.size():
			Sfx.play("click")
			_show(j)
	elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		var c: Dictionary = _chars[_focus]
		if shop:
			_buy(c)
		elif Save.is_unlocked(c["id"]):
			_choose(c)
