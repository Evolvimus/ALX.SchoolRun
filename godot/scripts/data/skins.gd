class_name Skins
extends RefCounted
## Event-Accessoires (Hüte), nur während bestimmter Zeiträume zu bekommen (siehe res://data/events.cfg).
## Einmal bekommen, bleiben sie für immer. Getragen wird eins für alle Figuren (Save.data["skin"]).

const LIST := {
	"partyhut": "Partyhut",
	"krone": "Krone",
	"zylinder": "Zylinder",
	"abihut": "Abi-Hut",
}

static var _events: Array = []
static var _anchors := {}


static func events() -> Array:
	if _events.is_empty():
		var cfg := ConfigFile.new()
		if cfg.load("res://data/events.cfg") == OK:
			for sec in cfg.get_sections():
				_events.append({ "id": sec, "name": cfg.get_value(sec, "name", sec), "start": cfg.get_value(sec, "start", ""),
					"end": cfg.get_value(sec, "end", ""), "skins": cfg.get_value(sec, "skins", []) })
	return _events


## Laufendes Event (oder leer)
static func active_event() -> Dictionary:
	var today := Daily.today()
	for e in events():
		if today >= str(e["start"]) and today <= str(e["end"]):
			return e
	return {}


static func owned() -> Array:
	return Save.data.get("skins_owned", [])


## Nach einem geschafften Level während eines Events: dessen Accessoires vergeben
static func grant_event() -> void:
	var e := active_event()
	if e.is_empty():
		return
	if not Save.data.has("skins_owned"):
		Save.data["skins_owned"] = []
	for id in e["skins"]:
		if LIST.has(id) and not id in Save.data["skins_owned"]:
			Save.data["skins_owned"].append(id)
			if Save.data["skin"] == "":
				Save.data["skin"] = id
			if not Nav.args.has("bot"):
				Nav.toast("acc-" + id, "EVENT · " + str(e["name"]).to_upper(), LIST[id] + " bekommen!")
	Save.persist()


## Wo sitzt der Kopf? Erste nicht-durchsichtige Zeile und Kopfbreite im Figurenbild (Bildpixel)
static func _anchor(key: String) -> Dictionary:
	if _anchors.has(key):
		return _anchors[key]
	var img: Image = Art.images.get(key)
	var res := { "pos": Vector2.ZERO, "width": 10.0, "size": Vector2.ONE }
	if img:
		res["size"] = Vector2(img.get_size())
		for y in img.get_height():
			var x0 := -1
			var x1 := -1
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					if x0 < 0:
						x0 = x
					x1 = x
			if x0 >= 0:
				# Kopfbreite ein paar Zeilen tiefer messen (oberste Zeile ist oft schmal)
				var w := float(x1 - x0 + 1)
				var y2 := mini(y + 3, img.get_height() - 1)
				var a := -1
				var b := -1
				for x in img.get_width():
					if img.get_pixel(x, y2).a > 0.5:
						if a < 0:
							a = x
						b = x
				if a >= 0:
					w = maxf(w, b - a + 1)
					res["pos"] = Vector2((a + b + 1) / 2.0, y)
				else:
					res["pos"] = Vector2((x0 + x1 + 1) / 2.0, y)
				res["width"] = w
				break
	_anchors[key] = res
	return res


## Accessoire an die Spielfigur (Sprite2D, zentriert mit offset (0, -h/2)) hängen
static func attach_sprite(view: Sprite2D, char_id: String) -> Sprite2D:
	var skin: String = Save.data.get("skin", "")
	if skin == "" or not skin in owned():
		return null
	var a := _anchor("char-" + char_id)
	var acc := Sprite2D.new()
	acc.texture = Art.tex("acc-" + skin)
	acc.centered = true
	var k: float = a["width"] / 12.0
	acc.scale = Vector2(k, k)
	var size: Vector2 = a["size"]
	acc.position = Vector2(a["pos"].x - size.x / 2, -size.y + a["pos"].y - acc.texture.get_height() * k / 2 + k)
	acc.set_meta("base_x", acc.position.x)
	view.add_child(acc)
	return acc


## Accessoire auf ein Figurenbild im Menü (TextureRect) setzen
static func attach_rect(tr: TextureRect, char_id: String) -> void:
	var skin: String = Save.data.get("skin", "")
	if skin == "" or not skin in owned():
		return
	var a := _anchor("char-" + char_id)
	var size: Vector2 = a["size"]
	var px := tr.size / size  # Bildschirmpixel je Bildpixel
	var acc := TextureRect.new()
	acc.texture = Art.tex("acc-" + skin)
	acc.stretch_mode = TextureRect.STRETCH_SCALE
	acc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k: float = a["width"] / 12.0
	tr.add_child(acc)
	acc.size = acc.texture.get_size() * k * px
	acc.position = Vector2(a["pos"].x * px.x - acc.size.x / 2, a["pos"].y * px.y - acc.size.y + k * px.y)
