class_name LevelBuilder
extends RefCounted
## Werkzeug: erzeugt den Kachelsatz für den Editor (levels/tileset.tres) und macht aus den Textkarten
## in tools/level_seeds.gd fertige Levelszenen (levels/<id>.tscn).
##
## Aufruf:   godot --path . -- --build-levels            (legt nur fehlende Szenen an)
##           godot --path . -- --build-levels --force    (überschreibt ALLE Levelszenen – Vorsicht!)
##
## Nach dem ersten Erzeugen werden die Level im Godot-Editor bearbeitet, nicht mehr hier.

const TILESET := "res://levels/tileset.tres"

## Zeichen → Grafik für das Kachelsymbol im Editor. Die Reihenfolge ist die Reihenfolge im Kachelsatz.
const TILES := [
	["#", "ground"], ["=", "platform"], ["R", "shelf"], ["L", "lab"], ["K", "box"], ["B", "crate"],
	["~", "crumble"], ["-", "mover"], ["|", "mover"], ["H", "ladder"], ["M", "mat"], ["^", "spikes"],
	["_", "plate-0"], ["D", "door"],
	["c", "leaf"], ["h", "heft"], ["S", "seed-1"], ["F", "tree-gold"], ["C", "cat-0"],
	["m", "mouse-0"], ["e", "plane"], ["w", "worm"], ["o", "ball"], ["<", "blower-0"], [">", "blower-0"],
	["N", "magnet"], ["f", "burner"],
	["P", "char-schueler"], ["T", "target"],
]
## Diese Kacheln sitzen im Spiel am oberen Rand der Zelle, alle anderen stehen unten.
const TOP_ALIGNED := "=~-|"


static func run(force: bool) -> void:
	var ts := _build_tileset()
	var err := ResourceSaver.save(ts, TILESET)
	print("Kachelsatz gespeichert: ", TILESET, " (", error_string(err), ")")
	ts = load(TILESET)
	for seed in LevelSeeds.all():
		var path := "res://levels/%s.tscn" % seed["id"]
		if ResourceLoader.exists(path) and not force:
			print("übersprungen (existiert schon): ", path)
			continue
		_build_scene(seed, ts, path)


static func _build_tileset() -> TileSet:
	var atlas_img := Image.create(TILES.size() * 15, 15, false, Image.FORMAT_RGBA8)
	for i in TILES.size():
		atlas_img.blit_rect(_icon(TILES[i][0], TILES[i][1]), Rect2i(0, 0, 15, 15), Vector2i(i * 15, 0))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(15, 15)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "ch")
	ts.set_custom_data_layer_type(0, TYPE_STRING)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(atlas_img)
	src.texture_region_size = Vector2i(15, 15)
	ts.add_source(src, 0)
	for i in TILES.size():
		src.create_tile(Vector2i(i, 0))
		src.get_tile_data(Vector2i(i, 0), 0).set_custom_data("ch", TILES[i][0])
	return ts


## 15x15-Symbol: die echte Grafik, bei Bedarf verkleinert, plus Pfeile für Richtungen.
static func _icon(ch: String, key: String) -> Image:
	var src: Image = Art.images[key].duplicate()
	if ch == ">":
		src.flip_x()
	var k := minf(1.0, minf(15.0 / src.get_width(), 15.0 / src.get_height()))
	if k < 1.0:
		src.resize(maxi(1, int(src.get_width() * k)), maxi(1, int(src.get_height() * k)), Image.INTERPOLATE_NEAREST)
	var icon := Image.create(15, 15, false, Image.FORMAT_RGBA8)
	var x := (15 - src.get_width()) / 2
	var y := 0 if TOP_ALIGNED.contains(ch) else 15 - src.get_height()
	icon.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))
	var arrow := Color("#ffe066")
	match ch:
		"-":  # fährt waagerecht
			for p in [[3, 10], [4, 9], [4, 11], [11, 10], [10, 9], [10, 11], [5, 10], [6, 10], [7, 10], [8, 10], [9, 10]]:
				icon.set_pixel(p[0], p[1], arrow)
		"|":  # fährt senkrecht
			for p in [[7, 7], [6, 8], [8, 8], [7, 13], [6, 12], [8, 12], [7, 8], [7, 9], [7, 10], [7, 11], [7, 12]]:
				icon.set_pixel(p[0], p[1], arrow)
		"<":
			for p in [[0, 2], [1, 1], [1, 3], [2, 2], [3, 2]]:
				icon.set_pixel(p[0], p[1], arrow)
		">":
			for p in [[14, 2], [13, 1], [13, 3], [12, 2], [11, 2]]:
				icon.set_pixel(p[0], p[1], arrow)
	return icon


static func _build_scene(seed: Dictionary, ts: TileSet, path: String) -> void:
	var coords := {}
	for i in TILES.size():
		coords[TILES[i][0]] = Vector2i(i, 0)
	var root := Node2D.new()
	root.name = "Level"
	root.set_script(load("res://scripts/data/level_def.gd"))
	root.set("title", seed["name"])
	root.set("background", seed["bg"])
	root.set("par_seconds", seed["par"])
	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = ts
	tiles.scale = Vector2(3, 3)
	root.add_child(tiles)
	tiles.owner = root
	var map: PackedStringArray = seed["map"]
	for y in map.size():
		for x in map[y].length():
			var ch := map[y][x]
			if ch != " ":
				assert(coords.has(ch), "Unbekanntes Zeichen im Level: " + ch)
				tiles.set_cell(Vector2i(x, y), 0, coords[ch])
	var hints := Node2D.new()
	hints.name = "Hints"
	root.add_child(hints)
	hints.owner = root
	for h in seed["hints"]:
		var l := Label.new()
		l.name = "Hint"
		l.text = h[2]
		l.position = Vector2(h[0] * 45, h[1] * 45)
		l.add_theme_font_size_override("font_size", 10)
		hints.add_child(l, true)
		l.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, path)
	print("Level gespeichert: ", path, " (", error_string(err), ") ", map[0].length(), "x", map.size(), " Kacheln")
	root.free()
