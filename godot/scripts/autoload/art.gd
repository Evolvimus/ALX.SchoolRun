extends Node
## Erzeugt beim Start alle Pixel-Grafiken per Code (keine Bilddateien nötig).
## Jede Grafik entsteht in Originalgröße (1 Bildpunkt = 1 Pixel) und wird beim Anzeigen hochskaliert:
## Welt und Gegner 3-fach, Blätter 2-fach, Figuren so, dass alle 90 px hoch sind.

## Echte Fotos/Zeichnungen der Lehrkräfte können als res://characters/<id>.png abgelegt werden;
## sie ersetzen dann die Pixel-Figur (Stehbild für alle Bewegungen).

const WORLD := 3.0

var textures := {}
## Die Rohbilder dazu (für den Kachel-Editor, siehe tools/level_builder.gd)
var images := {}
var _img: Image


func _ready() -> void:
	_characters()
	_weapons()
	_ginkgo()
	_terrain()
	_enemies()
	_misc()
	_bg_school()
	_bg_gym()
	_bg_lab()


func tex(key: String) -> Texture2D:
	return textures.get(key)


func has(key: String) -> bool:
	return textures.has(key)


## Bildschirmfarbe aus 0xRRGGBB
static func col(hex: int, a := 1.0) -> Color:
	var c := Color.hex((hex << 8) | 0xff)
	c.a = a
	return c


static func darken(hex: int, f := 0.7) -> int:
	var r := mini(255, int(((hex >> 16) & 255) * f))
	var g := mini(255, int(((hex >> 8) & 255) * f))
	var b := mini(255, int((hex & 255) * f))
	return (r << 16) | (g << 8) | b


# ------------------------------------------------------------------ Zeichenwerkzeuge

func _gen(key: String, w: int, h: int, draw: Callable) -> void:
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	draw.call()
	images[key] = _img
	textures[key] = ImageTexture.create_from_image(_img)


func px(x: float, y: float, w: float, h: float, hex: int, a := 1.0) -> void:
	var r := Rect2i(int(x), int(y), int(w), int(h)).intersection(Rect2i(Vector2i.ZERO, _img.get_size()))
	if r.size.x > 0 and r.size.y > 0:
		_img.fill_rect(r, col(hex, a))


func sprite(rows: Array, pal: Dictionary, ox := 0, oy := 0) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if pal.has(row[x]):
				px(ox + x, oy + y, 1, 1, pal[row[x]])


func blob(cx: int, cy: int, r: int, c: int) -> void:
	for y in range(-r, r + 1):
		var w := int(round(sqrt(r * r - y * y)))
		px(cx - w, cy + y, w * 2 + 1, 1, c)


func line(x0: int, y0: int, x1: int, y1: int, c: int, t := 1) -> void:
	var n := maxi(maxi(absi(x1 - x0), absi(y1 - y0)), 1)
	for i in n + 1:
		px(round(x0 + (x1 - x0) * float(i) / n), round(y0 + (y1 - y0) * float(i) / n), t, t, c)


func circle(cx: float, cy: float, r: float, c: int, a := 1.0) -> void:
	for y in range(int(cy - r), int(cy + r) + 1):
		for x in range(int(cx - r), int(cx + r) + 1):
			if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
				px(x, y, 1, 1, c, a)


## Mini-Pixelschrift (3x5) für Tafeln und Poster
const FONT := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."], "I": ["###", ".#.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"], "0": ["###", "#.#", "#.#", "#.#", "###"], "6": ["###", "#..", "###", "#.#", "###"],
	"E": ["###", "#..", "##.", "#..", "###"], "M": ["#.#", "###", "###", "#.#", "#.#"], "C": ["###", "#..", "#..", "#..", "###"],
	"=": ["...", "###", "...", "###", "..."], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"], "+": ["...", ".#.", "###", ".#.", "..."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."], "L": ["#..", "#..", "#..", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"], "O": ["###", "#.#", "#.#", "#.#", "###"], "P": ["##.", "#.#", "##.", "#..", "#.."],
	"S": [".##", "#..", ".#.", "..#", "##."], "8": ["###", "#.#", "###", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
	" ": ["...", "...", "...", "...", "..."],
}


func write(text: String, x: int, y: int, c: int) -> void:
	for i in text.length():
		sprite(FONT.get(text[i], FONT[" "]), { "#": c }, x + i * 4, y)


# ------------------------------------------------------------------ Figuren

const HEAD := [
	"...HHHHHH...", "..HHHHHHHH..", ".HHHHHHHHHH.", ".HHSSSSSSHH.", ".HSSSSSSSSH.", "..SEESSEES..",
	"..SSSSSSSS..", "..SSSMMSSS..", "...SSSSSS...",
]
const TORSO := ["..BBBDDBBB..", ".BBBBDDBBBB.", "SBBBBBBBBBBS", "SSBBBBBBBBSS", ".SBBBBBBBBS.", "..BBBBBBBB.."]
const TORSO_JUMP := ["S.BBBDDBBB.S", "SBBBBDDBBBBS", ".BBBBBBBBBB.", "..BBBBBBBB..", "..BBBBBBBB..", "..BBBBBBBB.."]
const LEGS := {
	"": ["..PPPPPPPP..", "..PPP..PPP..", "..PPP..PPP..", ".KKKK..KKKK.", ".KKKK..KKKK."],
	"-w1": ["..PPPPPPPP..", "..PPP..PPP..", "..PPP.KKKK..", ".KKKK.......", ".KKKK......."],
	"-w2": ["..PPPPPPPP..", "..PPP..PPP..", ".KKKK..PPP..", ".......KKKK.", ".......KKKK."],
	"-j": ["..PPPPPPPP..", ".PPPP..PPPP.", ".KKK....KKK.", "............", "............"],
}
const HAIR := [0x3b2414, 0x8a5a2b, 0xd9b44a, 0x1a1a1a, 0xa0a0a0, 0xb5452b]
const FRAMES := ["", "-i", "-w1", "-w2", "-j"]


func _characters() -> void:
	for i in Chars.all.size():
		var c: Dictionary = Chars.all[i]
		var id: String = c["id"]
		var photo := "res://characters/%s.png" % id
		if ResourceLoader.exists(photo):
			var t: Texture2D = load(photo)
			for f in FRAMES:
				textures["char-" + id + f] = t
			textures["bust-" + id] = t
			continue
		if Chars.is_detailed(c):
			var l: Dictionary = c["look"]
			for f in FRAMES:
				_gen("char-" + id + f, 36, 60, func(): _draw_detailed(l, f))
			_gen("bust-" + id, 36, 36, func(): _draw_detailed(l, ""))
			continue
		var pal := { "H": HAIR[i % HAIR.size()], "S": 0xf2c49b, "E": 0x1a1a2e, "M": 0xb5524a,
			"B": c["color"], "D": darken(c["color"]), "P": 0x2e3a5c, "K": 0x222222 }
		for f in FRAMES:
			var legs: Array = LEGS["" if f == "-i" else f]
			var rows: Array = HEAD + (TORSO_JUMP if f == "-j" else TORSO) + legs
			_gen("char-" + id + f, 12, 20, func(): sprite(rows, pal))
		_gen("bust-" + id, 12, 12, func(): sprite(HEAD + TORSO.slice(0, 3), pal))


## Detailfigur in dreifacher Auflösung (36x60) für Lehrkräfte mit eigenem Aussehen.
## f = "" (stehen), "-i" (stehen, zweites Bild), "-w1"/"-w2" (laufen), "-j" (springen)
func _draw_detailed(l: Dictionary, f: String) -> void:
	var skin: int = l["skin"]
	var skin_d := darken(skin, 0.86)
	var hair: int = l["hair"]
	var hair_d := darken(hair, 0.7)
	var jump := f == "-j"

	# --- Zopf (hinter Schulter und Arm, deshalb zuerst). Er schwingt beim Laufen und fliegt beim Springen hoch.
	if l.get("ponytail", false):
		var s := Vector2(-3, -9) if jump else Vector2(-3, -1) if f == "-w1" else Vector2(2, 0) if f == "-w2" else Vector2(1, 0) if f == "-i" else Vector2.ZERO
		# Segmente von oben (am Haargummi) nach unten (Spitze): [x, y, breite, höhe, anteil 0..1]
		for seg in [[5, 8, 3, 5, 0.0], [5, 13, 3, 4, 0.15], [4, 17, 3, 4, 0.35], [4, 21, 3, 4, 0.6], [4, 25, 3, 3, 0.8], [5, 28, 2, 3, 1.0], [6, 31, 1, 2, 1.15]]:
			var dx := roundi(s.x * seg[4])
			var dy := roundi(s.y * seg[4])
			px(seg[0] + dx, seg[1] + dy, seg[2], seg[3], hair)
			px(seg[0] + dx, seg[1] + dy, 1, seg[3], hair_d)
		px(5, 9, 3, 1, 0x1a1a1a)

	# --- Beine und Schuhe
	var pants: int = l["pants"]
	var shoes: int = l["shoes"]
	var leg := func(x: int, length: int, shoe_dx: int) -> void:
		px(x, 45, 7, length, pants)
		px(x, 45, 1, length, darken(pants, 0.8))
		px(x + 6, 45, 1, length, darken(pants, 0.8))
		px(x - 1 + shoe_dx, 45 + length, 9, 4, shoes)
		px(x - 1 + shoe_dx, 48 + length, 9, 1, darken(shoes, 0.6))
	px(10, 44, 16, 3, pants)
	if jump:
		leg.call(9, 6, -1); leg.call(20, 6, 1)
	elif f == "-w1":
		leg.call(8, 11, -1); leg.call(20, 8, 2)
	elif f == "-w2":
		leg.call(11, 8, 2); leg.call(21, 11, 1)
	else:
		leg.call(10, 11, 0); leg.call(19, 11, 0)

	# --- Arme (Hemdärmel) und Hände
	var shirt: int = l["shirt"]
	if jump:
		px(3, 22, 5, 9, shirt); px(28, 22, 5, 9, shirt); px(3, 22, 1, 9, darken(shirt)); px(32, 22, 1, 9, darken(shirt))
		px(5, 28, 5, 3, shirt); px(26, 28, 5, 3, shirt)
		px(3, 18, 4, 4, skin); px(29, 18, 4, 4, skin)
	else:
		var sw := 1 if f == "-w1" else -1 if f == "-w2" else 0
		px(5, 28, 5, 11 + sw, shirt); px(26, 28, 5, 11 - sw, shirt); px(5, 28, 1, 11 + sw, darken(shirt)); px(30, 28, 1, 11 - sw, darken(shirt))
		px(5, 39 + sw, 4, 4, skin); px(27, 39 - sw, 4, 4, skin); px(5, 42 + sw, 4, 1, skin_d); px(27, 42 - sw, 4, 1, skin_d)

	# --- Oberkörper: Strickweste mit V-Ausschnitt, Hemd, Krawatte, Gürtel
	var vest: int = l["vest"]
	var tie: int = l["tie"]
	px(10, 27, 16, 16, vest); px(10, 27, 1, 16, darken(vest)); px(25, 27, 1, 16, darken(vest))
	for y in range(28, 43, 2):
		for x in range(11 + (1 if y % 4 == 0 else 0), 25, 2):
			px(x, y, 1, 1, darken(vest, 0.85))
	for i in 8:
		var k := ceili(i / 2.0)
		px(14 + k, 27 + i, 8 - k * 2, 1, shirt)  # V-Ausschnitt
	px(13, 27, 3, 2, darken(shirt, 1.3)); px(20, 27, 3, 2, darken(shirt, 1.3))  # Kragen
	px(16, 27, 4, 2, tie); px(17, 29, 2, 7, tie); px(17, 29, 1, 7, darken(tie, 0.85)); px(17, 31, 2, 1, darken(tie, 0.7)); px(17, 34, 2, 1, darken(tie, 0.7))
	px(18, 37, 1, 1, 0x2a2a2a); px(18, 40, 1, 1, 0x2a2a2a)  # Knöpfe
	px(10, 43, 16, 2, l["belt"]); px(10, 44, 16, 1, darken(l["belt"])); px(17, 43, 2, 2, 0xd9c070)

	# --- Hals
	px(14, 24, 8, 3, skin_d)

	# --- Kopf (bewusst groß, damit man das Gesicht erkennt)
	var face: int = l.get("face_jump", l.get("face", 0)) if jump else l.get("face", 0)
	var oval := face > 0
	px(13, 0, 10, 1, skin); px(11, 1, 14, 1, skin); px(10, 2, 16, 1, skin); px(9, 3, 18, 3, skin)
	if oval:  # längliches Gesicht, das zum Kinn hin schmaler wird
		px(8, 6, 20, 10, skin); px(9, 16, 18, 2, skin); px(10, 18, 16, 2, skin); px(11, 20, 14, 1, skin)
		px(12, 21, 12, 1, skin); px(13, 22, 10, 1, skin); px(14, 23, 8, 1, skin); px(15, 24, 6, 1, skin)
	else:
		px(8, 6, 20, 15, skin); px(9, 21, 18, 1, skin); px(10, 22, 16, 1, skin); px(12, 23, 12, 1, skin); px(14, 24, 8, 1, skin)
	px(7, 13, 1, 4, skin); px(28, 13, 1, 4, skin); px(7, 16, 1, 1, skin_d); px(28, 16, 1, 1, skin_d)  # Ohren
	# Haare: straff nach hinten gekämmt, hoher Haaransatz mit leichten Geheimratsecken
	px(13, 0, 10, 1, hair); px(11, 1, 14, 1, hair); px(10, 2, 16, 1, hair); px(9, 3, 3, 1, hair); px(24, 3, 3, 1, hair); px(14, 3, 8, 1, hair)
	px(16, 4, 4, 1, hair_d); px(12, 3, 2, 1, hair_d); px(22, 3, 2, 1, hair_d)
	for x in [13, 16, 19, 22]:
		px(x, 0, 1, 3, hair_d)
	px(8, 3, 1, 3, hair); px(27, 3, 1, 3, hair); px(7, 5, 2, 8, hair); px(27, 5, 2, 8, hair)
	px(9, 4, 1, 6, hair_d); px(26, 4, 1, 6, hair_d)
	# Augenbrauen
	px(11, 8, 5, 1, darken(skin, 0.7)); px(20, 8, 5, 1, darken(skin, 0.7))
	# Brille: dünnes Gestell, durchsichtige Gläser, Augen dahinter
	var lens: int = l.get("lens", 0xf8dcc4)
	var glasses: int = l["glasses"]
	for x in [9, 19]:
		px(x + 1, 11, 6, 4, lens)
		px(x + 1, 10, 6, 1, glasses); px(x + 1, 15, 6, 1, glasses)
		px(x, 11, 1, 4, glasses); px(x + 7, 11, 1, 4, glasses)
		if face == 3:  # lachende Augen
			px(x + 3, 12, 2, 1, 0x1a1a2e); px(x + 2, 13, 1, 1, 0x1a1a2e); px(x + 5, 13, 1, 1, 0x1a1a2e)
		elif oval:  # kleine Augen
			px(x + 3, 12, 2, 2, 0x1a1a2e); px(x + 3, 12, 1, 1, 0x5a6a7a)
		else:  # große Augen
			px(x + 2, 12, 4, 2, 0xffffff); px(x + 3, 12, 2, 2, 0x1a1a2e)
		px(x + 5, 11, 1, 1, 0xffffff)  # Lichtreflex
	px(17, 12, 2, 1, glasses); px(8, 12, 1, 1, glasses); px(27, 12, 1, 1, glasses)  # Steg und Bügel
	var stubble: int = l["stubble"]
	var beard := darken(stubble, 0.72)
	var lip := 0x8a4038
	if oval:
		px(18, 13, 1, 5, skin_d); px(17, 18, 3, 1, skin_d); px(16, 17, 1, 1, skin_d)  # Nase
		px(10, 16, 2, 2, darken(skin, 0.93)); px(24, 16, 2, 2, darken(skin, 0.93))  # Wangen
		if face == 2:  # Bartschatten
			px(13, 19, 1, 3, stubble); px(22, 19, 1, 3, stubble); px(13, 21, 10, 1, stubble); px(14, 22, 8, 1, stubble)
		px(14, 19, 1, 1, lip); px(21, 19, 1, 1, lip)
		if face == 1:
			px(15, 20, 6, 1, lip)  # geschlossenes Lächeln
		else:
			px(15, 20, 6, 1, 0xf4ece4); px(15, 21, 6, 1, lip)  # Lächeln mit Zähnen
		px(16, 22, 4, 1, stubble); px(16, 23, 4, 2, beard); px(17, 25, 2, 1, beard)
	else:
		px(18, 14, 1, 4, skin_d); px(16, 18, 4, 1, skin_d)
		px(9, 17, 3, 2, darken(skin, 0.93)); px(24, 17, 3, 2, darken(skin, 0.93))
		px(13, 19, 1, 1, lip); px(22, 19, 1, 1, lip); px(14, 20, 8, 1, lip); px(15, 20, 6, 1, 0xf4ece4); px(15, 21, 6, 1, 0xb5605a)
		px(16, 22, 4, 1, stubble); px(15, 23, 6, 1, beard); px(16, 24, 4, 1, beard); px(17, 25, 2, 1, beard)


func _weapons() -> void:
	var hammer := func(handle: int, head: int, shine: int) -> void:
		px(0, 3, 12, 2, handle); px(0, 4, 12, 1, darken(handle))
		px(11, 0, 5, 8, head); px(11, 0, 5, 1, shine); px(15, 0, 1, 8, darken(head)); px(11, 7, 5, 1, darken(head))
	_gen("hammer", 16, 8, func(): hammer.call(0x8a5a2b, 0x8c8f99, 0xc9ccd6))
	_gen("hammer-gold", 16, 8, func(): hammer.call(0x5a3a22, 0xf2b61c, 0xfff0a0))
	_gen("ruler", 16, 3, func():
		px(0, 0, 16, 3, 0xffd23f); px(0, 2, 16, 1, 0xc99a14)
		for i in range(1, 16, 2):
			px(i, 0, 1, 2 if i % 4 == 1 else 1, 0x6b4a00))


# ------------------------------------------------------------------ Ginkgo (Schullogo)

## Breiter Fächer mit flachem Bogen oben, Kerbe in der Mitte, strahlenförmigen Adern und langem Stiel.
const LEAF := [
	".....ooooo.ooooo.....",
	"..ooollllo.ollllooo..",
	".olllyyddo.oddyylllo.",
	"olwwddwydyoydyyddyylo",
	"odwwwdwydylydyydyyyyo",
	"oddyyddydyyydyddyyddo",
	".oddyyddydyddydyyddo.",
	"..ooddydydydydyydoo..",
	"....oommmmmmmmmoo....",
	"......oommmmmoo......",
	"........ommmo........",
	".........ooo.........",
	"..........s..........",
	"..........s..........",
	"..........s..........",
	"...........s.........",
	"...........s.........",
	"............s........",
]
const GOLD := { "o": 0x6e3e00, "d": 0xe8a414, "y": 0xffc626, "l": 0xffde68, "m": 0xeea816, "w": 0xfff2b0, "s": 0x6e5012 }
const GREEN := { "o": 0x1c4612, "d": 0x4f9a2e, "y": 0x6cc04a, "l": 0x9ee07a, "m": 0x58a83a, "w": 0xd2f5b0, "s": 0x3a5a1a }
const WILT := { "o": 0x2a2116, "d": 0x4a3d28, "y": 0x5e5038, "l": 0x6f6046, "m": 0x54472f, "w": 0x7d6e52, "s": 0x3a2f1c }


func _ginkgo() -> void:
	_gen("leaf", 21, 18, func(): sprite(LEAF, GOLD))
	_gen("leaf-green", 21, 18, func(): sprite(LEAF, GREEN))
	_gen("leaf-wilt", 21, 18, func(): sprite(LEAF, WILT))
	var pot := func() -> void:
		px(3, 15, 9, 2, 0xd9764a); px(4, 17, 7, 5, 0xb5522e); px(4, 17, 1, 5, 0x8f3f22); px(5, 15, 5, 1, 0x3a2a1a)
	_gen("seed-0", 15, 22, func():
		pot.call(); px(7, 12, 1, 3, 0x4a8a2e); px(6, 11, 1, 1, 0x6cc04a); px(8, 12, 1, 1, 0x6cc04a))
	_gen("seed-1", 15, 22, func():
		pot.call(); px(7, 4, 1, 11, 0x4a8a2e)
		sprite([".g.g.", "ggggg", ".ggg.", "..g.."], { "g": 0x6cc04a }, 1, 6)
		sprite([".g.g.", "ggggg", ".ggg.", "..g.."], { "g": 0x8ed45f }, 9, 8)
		sprite([".y.y.", "yyyyy", ".yyy.", "..y.."], { "y": 0xffc928 }, 5, 0))
	_gen("tree-bare", 64, 78, func(): _tree(false))
	_gen("tree-gold", 64, 78, func(): _tree(true))


## Großer Ginkgo im Kübel (Levelziel): kahl oder golden
func _tree(gold: bool) -> void:
	px(20, 64, 24, 3, 0x9a9aa2); px(22, 67, 20, 11, 0x74747c); px(22, 67, 2, 11, 0x5c5c64); px(24, 64, 16, 1, 0x3a2a1a)
	px(30, 28, 4, 36, 0x6b4a2a); px(30, 28, 1, 36, 0x8a6238); px(33, 40, 1, 24, 0x4f3620)
	line(31, 42, 16, 26, 0x6b4a2a, 2); line(32, 38, 46, 22, 0x6b4a2a, 2); line(31, 30, 27, 12, 0x6b4a2a, 2)
	line(33, 30, 39, 10, 0x6b4a2a, 2); line(20, 30, 11, 30, 0x6b4a2a); line(42, 26, 53, 28, 0x6b4a2a)
	var crown := [[16, 22, 9], [46, 18, 10], [27, 10, 9], [39, 8, 8], [31, 20, 11], [10, 31, 6], [54, 28, 6], [22, 31, 7], [42, 30, 7]]
	if not gold:
		for i in crown.size():
			var c: Array = crown[i]
			if i % 2 == 0:
				blob(c[0], c[1] - 1, 2, 0x5aa03c)
			px(c[0] + c[2] - 3, c[1] + 2, 2, 2, 0x7d9a4a)
		return
	for c in crown:
		blob(c[0], c[1] + 1, c[2], 0xc98f10)
	for c in crown:
		blob(c[0], c[1], c[2] - 1, 0xf2b61c)
	for c in crown:
		blob(c[0] - 2, c[1] - 2, maxi(2, c[2] - 4), 0xffd84a)
	for i in 90:
		var x := 4 + ((i * 37) % 56)
		var y := 2 + ((i * 23 + (i >> 2) * 7) % 36)
		for c in crown:
			if (x - c[0]) ** 2 + (y - c[1]) ** 2 < (c[2] - 1.5) ** 2:
				px(x, y, 1, 1, 0xfff0a0 if i % 2 else 0xd99a00)
				break


# ------------------------------------------------------------------ Gelände

func _terrain() -> void:
	var dark := func(top: bool) -> void:
		px(0, 0, 15, 15, 0x26262b)
		for i in 14:
			px((i * 7 + (3 if top else 0)) % 15, (i * 11 + 4) % 15, 2, 1, 0x34343b if i % 2 else 0x1b1b1f)
		if top:
			px(0, 0, 15, 2, 0xd9652b); px(0, 2, 15, 1, 0x8a3a14); px(0, 0, 15, 1, 0xf08a4b)
	_gen("ground", 15, 15, func(): dark.call(true))
	_gen("under", 15, 15, func(): dark.call(false))
	_gen("platform", 15, 6, func():
		px(0, 0, 15, 6, 0x8f5a2e); px(0, 0, 15, 2, 0xd69a5c); px(0, 5, 15, 1, 0x4a2c17); px(1, 3, 2, 1, 0x6b4426))
	_gen("box", 15, 15, func():
		px(0, 0, 15, 15, 0xd9a05b); px(0, 0, 15, 2, 0xd9652b)
		for y in [5, 9, 13]:
			px(0, y, 15, 1, 0x9a6a33)
		px(0, 2, 1, 13, 0xb5803f); px(14, 2, 1, 13, 0x9a6a33))
	_gen("shelf", 15, 15, func():
		px(0, 0, 15, 15, 0x5a3820); px(0, 0, 15, 2, 0xb5763f); px(0, 8, 15, 1, 0xb5763f); px(0, 14, 15, 1, 0x3d2513)
		var books := [0xd23b3b, 0x3d6fb6, 0xe0a23b, 0x4fa36b, 0x8a5fc4, 0xf4f4f4, 0x2a8a8a]
		for i in 7:
			px(i * 2 + (1 if i > 3 else 0), 3, 2, 5, books[i])
			px(i * 2 + 1, 9 + (i % 2), 2, 5 - (i % 2), books[(i + 3) % 7])
		px(1, 4, 1, 1, 0xffffff); px(9, 5, 1, 1, 0x222222))
	_gen("lab", 15, 15, func():
		px(0, 0, 15, 15, 0xe4e8ea); px(0, 0, 15, 3, 0x2f3640); px(0, 0, 15, 1, 0x4a5563); px(0, 3, 15, 1, 0x9aa3a8)
		px(7, 4, 1, 11, 0xb9c1c6); px(3, 8, 2, 1, 0x7d868b); px(10, 8, 2, 1, 0x7d868b); px(0, 14, 15, 1, 0x9aa3a8))
	_gen("crate", 15, 15, func():
		px(0, 0, 15, 15, 0xb8834c); px(0, 0, 15, 1, 0xd9a86c); px(0, 14, 15, 1, 0x7a5228); px(14, 0, 1, 15, 0x7a5228)
		px(6, 0, 3, 15, 0xd9c7a0); write("ABI", 2, 8, 0x8a2b2b))
	_gen("mat", 15, 5, func():
		px(0, 0, 15, 5, 0x2d6fd6); px(0, 0, 15, 1, 0x5a97f0); px(0, 4, 15, 1, 0x1b4a99); px(0, 0, 1, 5, 0x1b4a99); px(14, 0, 1, 5, 0x1b4a99))
	_gen("spikes", 15, 15, func():
		for i in 3:
			var x := i * 5
			px(x + 2, 9, 1, 5, 0xd8d8d8); px(x, 12, 5, 2, 0xd23b3b); px(x + 1, 11, 3, 1, 0xff6b6b))
	# Klassenzimmertür (4 Kacheln hoch), mit Ginkgo-Aufkleber und Schloss-Lampe
	var door := func(open: bool) -> void:
		px(0, 0, 15, 60, 0x4a2c17); px(1, 1, 13, 59, 0x8f5a2e); px(1, 1, 1, 59, 0xa8703f)
		px(3, 6, 9, 14, 0x2a1a0e); px(4, 7, 7, 12, 0xbfe6ff); px(4, 7, 7, 2, 0xe3f4ff)
		sprite([".y.y.", "yyyyy", ".yyy.", "..y..", "..s.."], { "y": 0xffc626, "s": 0x6e5012 }, 5, 10)
		px(3, 26, 9, 12, 0x7a4b2a); px(3, 42, 9, 12, 0x7a4b2a)
		px(11, 33, 2, 3, 0xd9c060)
		px(6, 2, 3, 3, 0x5be05b if open else 0xff3b3b)
	_gen("door", 15, 60, func(): door.call(false))
	_gen("door-open", 15, 60, func(): door.call(true))
	# Bröckelbrett: Kreideablage mit Rissen
	_gen("crumble", 15, 6, func():
		px(0, 0, 15, 6, 0xcdb38a); px(0, 0, 15, 1, 0xf0e0bf); px(0, 5, 15, 1, 0x8a7350)
		px(4, 1, 1, 3, 0x8a7350); px(5, 3, 1, 2, 0x8a7350); px(10, 0, 1, 2, 0x8a7350); px(11, 2, 1, 3, 0x8a7350); px(1, 4, 2, 1, 0xffffff))
	# Rollwagen (bewegliche Plattform, 2 Kacheln breit)
	_gen("mover", 30, 6, func():
		px(0, 0, 30, 3, 0xb9c1c6); px(0, 0, 30, 1, 0xe4e8ea); px(0, 3, 30, 1, 0x5f676b)
		px(2, 4, 4, 2, 0x222222); px(24, 4, 4, 2, 0x222222); px(13, 4, 4, 1, 0x7d868b); px(1, 1, 1, 1, 0xd23b3b); px(28, 1, 1, 1, 0xd23b3b))
	# Sprossenwand zum Klettern
	_gen("ladder", 15, 15, func():
		px(2, 0, 2, 15, 0xa8703f); px(11, 0, 2, 15, 0xa8703f); px(2, 0, 1, 15, 0xc98b4f); px(11, 0, 1, 15, 0xc98b4f)
		for y in [2, 7, 12]:
			px(2, y, 11, 2, 0xd69a5c); px(2, y + 1, 11, 1, 0x8f5a2e))
	# Druckplatte: oben = frei, gedrückt = flach und grün
	_gen("plate-0", 15, 4, func():
		px(0, 2, 15, 2, 0x555b66); px(2, 0, 11, 2, 0xd23b3b); px(2, 0, 11, 1, 0xff7b7b))
	# Arena-Gitter (4 Kacheln hoch): Metallstäbe mit Warnlampe
	var gate := func(closed: bool) -> void:
		px(0, 0, 15, 4, 0x2f3640); px(0, 56, 15, 4, 0x2f3640)
		for x in [1, 5, 9, 13]:
			px(x, 4, 2, 52, 0x7d868b); px(x, 4, 1, 52, 0xb9c1c6)
		for y in [18, 38]:
			px(0, y, 15, 2, 0x555b66)
		px(6, 0, 3, 3, 0xff3b3b if closed else 0x5be05b)
	_gen("gate", 15, 60, func(): gate.call(true))
	_gen("gate-open", 15, 60, func(): gate.call(false))
	# Spawner: Lüftungsklappe an der Decke, aus der Staubmäuse fallen
	_gen("spawner", 15, 6, func():
		px(0, 0, 15, 6, 0x555b66); px(1, 1, 13, 4, 0x1b1b1f)
		for x in range(2, 14, 3):
			px(x, 1, 1, 4, 0x7d868b)
		px(0, 5, 15, 1, 0x2f3640))
	_gen("plate-1", 15, 4, func():
		px(0, 2, 15, 2, 0x555b66); px(2, 1, 11, 1, 0x5be05b))


# ------------------------------------------------------------------ Gegner

func _enemies() -> void:
	var mouse := { "g": 0x8d8d96, "l": 0xb4b4be, "d": 0x62626a, "w": 0xffffff, "k": 0x1a1a1a, "p": 0xff9bb0 }
	_gen("mouse-0", 11, 8, func(): sprite(["..d.gggl...", ".ggglgggg..", "pgggggglggd", "gwkgggggggg", "ggggglggggg", ".ggggggggl.", "..g..g..g.."], mouse, 0, 1))
	_gen("mouse-1", 11, 8, func(): sprite(["...dgggl...", ".ggglgggg.d", "pgggggglggd", "gwkgggggggg", "ggggglggggg", ".ggggggggl.", ".g..g..g..."], mouse, 0, 0))
	_gen("plane", 14, 7, func(): sprite(["#.............", "###...........", "#####.........", "##############", ".#########....", "..######......", "...##........."], { "#": 0xf4f4f4 }))
	_gen("paperball", 6, 6, func(): sprite([".wwww.", "wwdwww", "wdwwdw", "wwwdww", "wwdwww", ".wwww."], { "w": 0xf4f4f4, "d": 0xbdbdbd }))
	_gen("worm", 9, 18, func(): sprite([
		"..ggggg..", ".ggggggg.", "kkkkgkkkk", "kwwkgkwwk", "kkkkgkkkk", ".ggggggg.", ".ggmmmgg.", "..ggggg..",
		".ggggggg.", ".glllllg.", ".ggggggg.", ".glllllg.", ".ggggggg.", ".glllllg.", ".ggggggg.", ".glllllg.", ".ggggggg.", ".glllllg.",
	], { "g": 0x9bc53d, "l": 0xcfe57a, "k": 0x222222, "w": 0xdff4ff, "m": 0x5a2a2a }))
	_gen("hole", 13, 3, func():
		px(1, 0, 11, 3, 0x0c0c0e); px(0, 1, 13, 1, 0x0c0c0e); px(2, 0, 2, 1, 0xf4f4f4); px(9, 2, 2, 1, 0xd9c7a0))
	# Laubbläser (Düse zeigt nach links)
	var blower := func(f: int, broken: bool) -> void:
		var body := 0x4a3a30 if broken else 0xe8742a
		var dk := 0x2a2420 if broken else 0xa84a12
		px(8, 3 + f, 8, 7, body); px(8, 9 + f, 8, 1, dk); px(10, 1 + f, 5, 2, 0x222222); px(11, 5 + f, 3, 3, 0x333333 if broken else 0xffd23f)
		px(3, 5 + f, 5, 4, 0x555b66); px(0, 4 + f, 3, 6, 0x7d8590); px(0, 4 + f, 1, 6, 0x222222)
		px(9, 10, 2, 1, 0x222222); px(13, 10, 2, 1, 0x222222)
	_gen("blower-0", 16, 11, func(): blower.call(0, false))
	_gen("blower-1", 16, 11, func(): blower.call(-1, false))
	_gen("blower-x", 16, 11, func(): blower.call(0, true))
	# Hufeisenmagnet (Öffnung nach unten)
	_gen("magnet", 13, 12, func():
		px(2, 0, 9, 4, 0xd23b3b); px(1, 1, 11, 3, 0xd23b3b); px(0, 2, 4, 7, 0xd23b3b); px(9, 2, 4, 7, 0xd23b3b)
		px(3, 1, 6, 1, 0xff7b7b); px(0, 9, 4, 3, 0xdcdfe4); px(9, 9, 4, 3, 0xdcdfe4); px(0, 11, 4, 1, 0x9aa3a8); px(9, 11, 4, 1, 0x9aa3a8))
	# Bunsenbrenner + Flamme
	_gen("burner", 9, 8, func():
		px(3, 0, 3, 6, 0xb9c1c6); px(3, 0, 1, 6, 0xe4e8ea); px(2, 3, 5, 1, 0x7d868b); px(0, 6, 9, 2, 0x2f3640); px(7, 5, 2, 1, 0x3d6fb6))
	var flame := func(f: int) -> void:
		for y in 30:
			var t := y / 29.0
			var half := mini(3, roundi(t * 10 if t < 0.3 else 3.0 - ((t - 0.85) * 10 if t > 0.85 else 0.0)))
			var wob := roundi(sin(y * 0.8 + f * 2.4) * (1 - t) * 1.2)
			var outer := 0xff7a1a if t < 0.45 else 0xffb52e if t < 0.8 else 0x4aa8ff
			var inner := 0xffd23f if t < 0.45 else 0xfff0a0 if t < 0.8 else 0xbfe6ff
			px(3 - half + wob, y, half * 2 + 1, 1, outer)
			if half > 1:
				px(4 - half + wob, y, half * 2 - 1, 1, inner)
	_gen("flame-0", 7, 30, func(): flame.call(0))
	_gen("flame-1", 7, 30, func(): flame.call(1))
	# Raupe (Blattdieb)
	var cat := { "g": 0x7ac74f, "d": 0x4f9a2e, "k": 0x2a2a1a, "w": 0xffffff }
	_gen("cat-0", 10, 5, func(): sprite(["..........", "kk.gg.gg..", "kwggdggdgg", "kkggggdggg", ".d..d..d.d"], cat))
	_gen("cat-1", 10, 5, func(): sprite(["....gg....", "kk.gddg...", "kwgg..gggg", "kkgg..dggg", ".d.d...d.d"], cat))
	# Boss: Der Kopierer (40x30). Zu = gepanzert, offen = Deckel hoch, Inneres glüht (verwundbar)
	var copier := func(open: bool, hot: bool) -> void:
		var body := 0xd9dde2
		var dk := 0x9aa3a8
		px(2, 10, 36, 18, body); px(2, 10, 36, 1, 0xf4f6f8); px(2, 27, 36, 1, dk); px(2, 10, 1, 18, 0xeef1f4); px(37, 10, 1, 18, dk)
		px(4, 28, 4, 2, 0x2f3640); px(32, 28, 4, 2, 0x2f3640)                     # Füße
		px(6, 18, 22, 3, 0x2f3640); px(7, 19, 20, 1, 0x555b66)                     # Papierausgabe
		px(6, 22, 22, 2, 0xf4f4f4); px(8, 22, 18, 1, 0xbdbdbd)                     # Papierstapel
		px(30, 13, 6, 6, 0x2f3640); px(31, 14, 4, 2, 0x5bc0eb if not hot else 0xff3b3b) # Display
		px(31, 17, 1, 1, 0x5be05b); px(33, 17, 1, 1, 0xffd23f); px(35, 17, 1, 1, 0xff3b3b)
		px(5, 13, 3, 2, 0x555b66); px(9, 13, 3, 2, 0x555b66)                      # Lüftung
		# „Gesicht“: zwei böse Augen im Scannerglas
		if open:
			px(1, 0, 38, 3, 0x9aa3a8); px(1, 0, 38, 1, 0xc9ccd6); px(3, 3, 34, 7, 0x2f3640) # Deckel hoch
			px(4, 4, 32, 5, 0xfff0a0); px(6, 5, 28, 3, 0xffffff)                       # grelles Licht = Schwachstelle
			px(12, 6, 4, 1, 0x2a2a3a); px(24, 6, 4, 1, 0x2a2a3a)
		else:
			px(1, 7, 38, 4, 0x9aa3a8); px(1, 7, 38, 1, 0xc9ccd6); px(3, 11, 34, 1, 0x555b66)  # Deckel zu
			px(10, 8, 6, 2, 0xff3b3b if hot else 0x2a2a3a); px(24, 8, 6, 2, 0xff3b3b if hot else 0x2a2a3a)
			px(12, 8, 2, 1, 0xffffff); px(26, 8, 2, 1, 0xffffff)
	_gen("copier", 40, 30, func(): copier.call(false, false))
	_gen("copier-hot", 40, 30, func(): copier.call(false, true))
	_gen("copier-open", 40, 30, func(): copier.call(true, false))
	_gen("sheet", 7, 5, func():
		px(0, 0, 7, 5, 0xf4f4f4); px(1, 1, 5, 1, 0x9aa3a8); px(1, 3, 4, 1, 0x9aa3a8); px(6, 0, 1, 5, 0xbdbdbd))
	_gen("paperwave", 15, 8, func():
		for i in 4:
			px(i * 2, 6 - i * 2, 15 - i * 3, 2, 0xf4f4f4 if i % 2 == 0 else 0xdadde2)
		px(0, 7, 15, 1, 0x9aa3a8); px(12, 0, 3, 2, 0xff7b7b))
	_gen("ball", 8, 8, func(): sprite(["..oooo..", ".ookooo.", "oookoooo", "kkkkkkkk", "oookoooo", "oookoooo", ".ookooo.", "..oooo.."], { "o": 0xe8742a, "k": 0x5a2a0c }))
	# Übungsscheibe auf Holzständer
	_gen("target", 15, 22, func():
		px(6, 13, 3, 8, 0x8f5a2e); px(3, 20, 9, 2, 0x6b4426)
		blob(7, 7, 7, 0x6e3e00); blob(7, 7, 6, 0xf4f4f4); blob(7, 7, 4, 0xd23b3b); blob(7, 7, 2, 0xf4f4f4); px(6, 6, 3, 3, 0xd23b3b))


func _misc() -> void:
	# Geheimheft
	_gen("heft", 9, 11, func():
		px(0, 0, 9, 11, 0x2b4fa8); px(0, 0, 1, 11, 0x1a2f66); px(8, 0, 1, 11, 0x1f3a80); px(1, 10, 8, 1, 0x1f3a80)
		px(2, 2, 5, 3, 0xf4f4f4); px(3, 3, 3, 1, 0x9aa3a8); px(3, 7, 3, 2, 0xffc626); px(4, 9, 1, 1, 0x6e5012))
	# Medaillen: alle Blätter, ohne Treffer, unter Zielzeit
	var medal := func(symbol: Array, pal: Dictionary) -> void:
		circle(5.5, 5.5, 5.5, 0x8a5a00); circle(5.5, 5.5, 4.5, 0xffc626); circle(4.5, 4.5, 2.0, 0xffe98a)
		sprite(symbol, pal, 3, 3)
	_gen("medal-leaves", 11, 11, func(): medal.call(["g.g.g", "ggggg", ".ggg.", "..g..", "..g.."], { "g": 0x2f7a22 }))
	_gen("medal-clean", 11, 11, func(): medal.call([".r.r.", "rrrrr", "rrrrr", ".rrr.", "..r.."], { "r": 0xc0282d }))
	_gen("medal-time", 11, 11, func(): medal.call([".kkk.", "k.k.k", "k.kkk", "k...k", ".kkk."], { "k": 0x2b2b3a }))
	_gen("check", 9, 7, func(): sprite(["........#", ".......##", "#.....##.", "##...##..", ".##.##...", "..###....", "...#....."], { "#": 0x6cff6c }))
	_gen("dot", 1, 1, func(): px(0, 0, 1, 1, 0xffffff))
	_gen("touch", 30, 30, func(): circle(15, 15, 15, 0xffffff, 0.22))
	_icons()


## Symbole für Menüs und Bedienung (weiß, werden per modulate eingefärbt)
func _icons() -> void:
	var W := { "#": 0xffffff }
	_gen("icon-back", 10, 8, func(): sprite(["...#......", "..##......", ".###......", "##########", "##########", ".###......", "..##......", "...#......"], W))
	_gen("icon-jump", 11, 10, func(): sprite(["....###....", "...#####...", "..#######..", ".####.####.", "####...####", "###.....###", "...........", "...#####...", "...#####...", "...#####..."], W))
	_gen("icon-clock", 11, 11, func(): sprite(["...#####...", "..#.....#..", ".#...#...#.", "#....#....#", "#....#....#", "#....###..#", "#.........#", "#.........#", ".#.......#.", "..#.....#..", "...#####..."], W))
	_gen("icon-pause", 8, 10, func(): for y in 10: sprite(["###..###"], W, 0, y))
	_gen("icon-play", 8, 10, func(): sprite(["#.......", "###.....", "#####...", "#######.", "########", "########", "#######.", "#####...", "###.....", "#......."], W))
	_gen("icon-sound", 10, 8, func(): sprite(["...#......", "..##...#..", "####.#..#.", "####..#.#.", "####..#.#.", "####.#..#.", "..##...#..", "...#......"], W))
	_gen("icon-mute", 10, 8, func(): sprite(["...#......", "..##......", "####.#..#.", "####..##..", "####..##..", "####.#..#.", "..##......", "...#......"], W))
	_gen("icon-lock", 9, 11, func(): sprite(["..#####..", ".##...##.", ".#.....#.", ".#.....#.", "#########", "#########", "####.####", "####.####", "#########", "#########", "#########"], W))
	_gen("icon-restart", 10, 10, func(): sprite(["...####...", ".##....#..", ".#.....###", "#.......#.", "#.........", "#.........", "#.......#.", ".#.....#..", ".##...##..", "...###...."], W))
	_gen("icon-map", 11, 10, func(): sprite(["###.....###", "#.###.###.#", "#...###...#", "#.#.#.#...#", "#...#.#.#.#", "#.#.#.#...#", "#...#.#.#.#", "#.#.#.#...#", "###.#.#.###", "...###.###."], W))
	_gen("icon-star", 11, 10, func(): sprite([".....#.....", "....###....", "....###....", "###########", ".#########.", "..#######..", "..#######..", ".####.####.", ".###...###.", ".#.......#."], W))
	_gen("icon-coin", 9, 9, func():
		circle(4.5, 4.5, 4.5, 0x9a6400); circle(4.5, 4.5, 3.6, 0xffc626); circle(3.8, 3.8, 1.6, 0xffe98a); px(4, 2, 1, 5, 0xb07a10))
	_gen("icon-card", 8, 10, func():
		px(0, 0, 8, 10, 0xffffff); px(1, 1, 6, 8, 0x2a2f5a); px(2, 2, 4, 4, 0xffcc33); px(2, 7, 4, 1, 0xffffff))
	_gen("icon-code", 14, 10, func():
		px(1, 0, 12, 10, 0xffcc33); px(0, 1, 14, 8, 0xffcc33); px(1, 1, 12, 2, 0xffe98a)
		for i in 3:
			px(2 + i * 4, 4, 3, 2, 0x2b1a00)
		px(2, 7, 10, 1, 0xb8860b))
	_gen("icon-shop", 14, 12, func():
		for k in 3:
			var y := 8 - k * 3
			px(1, y, 10, 3, 0x9a6400); px(2, y, 8, 2, 0xffc626); px(3, y, 2, 1, 0xffe98a)
		circle(10.5, 7.5, 3.5, 0x9a6400); circle(10.5, 7.5, 2.6, 0xffc626); px(10, 6, 1, 3, 0xb07a10))
	_gen("icon-book", 14, 11, func():
		px(0, 1, 7, 10, 0x5ab0ff); px(7, 1, 7, 10, 0x3d8be0); px(1, 0, 5, 10, 0xf4f4f4); px(8, 0, 5, 10, 0xe4e4ee)
		for r in 4:
			px(2, 2 + r * 2, 3, 1, 0x9aa3c8); px(9, 2 + r * 2, 3, 1, 0x9aa3c8))
	# weicher Lichtschein (für Intro und Figurenbühne)
	_gen("glow", 64, 64, func():
		for y in 64:
			for x in 64:
				var d := Vector2(x - 31.5, y - 31.5).length() / 32.0
				if d < 1.0:
					px(x, y, 1, 1, 0xffffff, pow(1.0 - d, 2.2)))


# ------------------------------------------------------------------ Hintergründe (640x135, 3-fach gezeigt)

func _bg_school() -> void:
	_gen("bg-school", 640, 135, func():
		px(0, 0, 640, 135, 0xe9dcb5)
		for x in range(0, 640, 8):
			px(x, 10, 1, 95, 0xd9c99c)  # Tapetenstreifen
		px(0, 0, 640, 10, 0xbfb59a); px(0, 9, 640, 1, 0x8f866c)  # Decke
		px(0, 105, 640, 30, 0x6f9a86); px(0, 105, 640, 2, 0x4e7362)  # Wandfliesen
		for x in range(0, 640, 10):
			px(x, 107, 1, 28, 0x5f8a76)
		for x in [40, 200, 360, 520]:
			px(x, 10, 50, 3, 0xffffff); px(x, 13, 50, 1, 0xcfe9ff)  # Neonröhren
		# ---- Klassenzimmer (0-320)
		px(18, 30, 136, 62, 0x6b4426); px(21, 33, 130, 56, 0x2f5d3a)  # Tafel
		write("ABI 2026", 30, 40, 0xf4f4f4); write("E=MC2", 30, 52, 0xf4f4f4); write("1+1=2", 30, 64, 0xffe66d)
		px(95, 45, 40, 1, 0xdfe9df); px(95, 45, 1, 25, 0xdfe9df); px(96, 66, 6, 1, 0xdfe9df)
		for i in 6:
			px(98 + i * 6, 64 - i * 3, 2, 2, 0xff9bd5)
		px(18, 92, 136, 3, 0x8f5a2e); px(40, 90, 6, 2, 0xffffff); px(55, 90, 8, 2, 0xffe066)  # Kreideablage
		circle(175, 42, 9, 0x333333); circle(175, 42, 8, 0xffffff)  # Uhr
		px(175, 36, 1, 6, 0x222222); px(175, 42, 4, 1, 0x222222)
		for wx in [196, 256]:  # Fenster
			px(wx, 26, 52, 64, 0xf4f4f4); px(wx + 3, 29, 46, 58, 0x8fd3ff); px(wx + 3, 70, 46, 17, 0x7fc4ef)
			px(wx + 25, 29, 2, 58, 0xf4f4f4); px(wx + 3, 57, 46, 2, 0xf4f4f4)
			px(wx + 8, 36, 12, 4, 0xffffff); px(wx + 11, 33, 6, 3, 0xffffff); px(wx + 32, 45, 10, 3, 0xffffff)
			px(wx + 4, 78, 20, 9, 0x5bb04f); px(wx - 2, 90, 56, 3, 0xd9d0b8)
		for dx in [20, 85, 150, 215, 280]:
			_desk(dx)
		# ---- Schulflur (320-640)
		var locker_colors := [0x3d6fb6, 0xc94a4a, 0x3d6fb6, 0xe0a23b, 0x3d6fb6, 0x4fa36b, 0x3d6fb6]
		for i in 7:  # Spinde
			var lx := 330 + i * 19
			px(lx, 40, 18, 65, locker_colors[i])
			px(lx, 40, 18, 2, 0xffffff); px(lx + 17, 40, 1, 65, 0x22344f)
			for v in 3:
				px(lx + 4, 46 + v * 3, 10, 1, 0x22344f)
			px(lx + 13, 70, 2, 5, 0xd0d0d0)
		px(480, 32, 52, 40, 0x8a5a2b); px(482, 34, 48, 36, 0xc9975b)  # Pinnwand
		for n in [[486, 38, 0xffffff], [500, 37, 0xffe66d], [515, 40, 0xff9bd5], [489, 54, 0x9be7ff], [505, 52, 0xffffff], [517, 56, 0xb5f5a0]]:
			px(n[0], n[1], 11, 12, n[2]); px(n[0] + 5, n[1], 1, 1, 0xd23b3b)
		px(545, 30, 26, 36, 0xd23b3b); write("ABI", 552, 36, 0xffffff); write("26", 554, 46, 0xffcc33); px(549, 58, 18, 2, 0xffffff)  # Poster
		px(585, 38, 40, 67, 0x7a4b2a); px(588, 41, 34, 64, 0xa8703f)  # Tür
		px(594, 47, 22, 18, 0xbfe6ff); px(616, 75, 3, 2, 0xe0c060)
		px(588, 24, 34, 9, 0x2a7a3a); write("EXIT", 592, 26, 0xffffff)
		for dx in [340, 440]:
			_bench(dx))


func _bg_gym() -> void:
	_gen("bg-gym", 640, 135, func():
		px(0, 0, 640, 135, 0xe6e6ec)
		px(0, 0, 640, 31, 0x17171a); px(0, 31, 640, 1, 0x8a8a8a)  # Dachträger
		for x in range(0, 640, 16):
			px(x, 25, 10, 2, 0x2c2c31); px(x + 6, 28, 8, 1, 0x2c2c31)
		for wx in [20, 150, 330, 470]:  # Fensterband
			px(wx, 36, 100, 28, 0x162744); px(wx + 2, 38, 96, 24, 0x4d86a8)
			for i in 20:
				px(wx + 30 + i, 60 - i, 6, 1, 0x6fa3bf); px(wx + 62 + i, 60 - i, 3, 1, 0x6fa3bf)
			px(wx + 24, 38, 1, 24, 0x162744); px(wx + 75, 38, 1, 24, 0x162744); px(wx + 25, 52, 50, 1, 0x162744)
		px(0, 82, 640, 53, 0x2f4f9e); px(0, 82, 640, 1, 0x1f3572)  # Prallschutzwand
		for i in 420:
			px((i * 37) % 640, 84 + (i * 53) % 50, 1, 1, 0x4a6bc0 if i % 3 else 0x8aa3e0)
		px(266, 60, 50, 17, 0x111111); px(267, 61, 48, 15, 0x2a2a2a)  # Anzeigetafel
		write("12", 271, 66, 0xff3b3b); write("08", 303, 66, 0xff3b3b); px(290, 67, 1, 1, 0xffcc33); px(290, 70, 1, 1, 0xffcc33)
		px(556, 54, 34, 24, 0x111111); px(557, 55, 32, 22, 0xffffff)  # Basketballkorb
		px(566, 62, 14, 10, 0x111111); px(567, 63, 12, 8, 0xffffff)
		px(568, 73, 10, 1, 0xe8742a)
		for i in 4:
			px(569 + i * 2 + (i % 2), 74, 1, 4, 0xcfcfcf)
		for sx in [112, 440]:  # Sprossenwände
			px(sx, 86, 2, 49, 0xa8703f); px(sx + 17, 86, 2, 49, 0xa8703f); px(sx + 34, 86, 2, 49, 0xa8703f)
			for y in range(89, 134, 5):
				px(sx, y, 36, 1, 0xc98b4f)
		px(60, 92, 22, 43, 0x0e1530); px(61, 93, 20, 42, 0x2a4488); px(77, 112, 2, 1, 0xc0c0c0)  # Tür
		px(52, 100, 3, 3, 0xffffff); px(53, 101, 1, 1, 0x2a4488))


func _bg_lab() -> void:
	_gen("bg-lab", 640, 135, func():
		px(0, 0, 640, 135, 0xdfe9e4)
		px(0, 0, 640, 24, 0xb8c4be); px(0, 23, 640, 1, 0x8b9690)
		for x in range(0, 640, 80):
			px(x + 15, 24, 50, 2, 0xffffff); px(x + 15, 26, 50, 1, 0xcfe9ff)
		px(0, 105, 640, 30, 0x9fc4d6); px(0, 105, 640, 1, 0x6f9db2); px(0, 120, 640, 1, 0x86b3c8)
		for x in range(0, 640, 10):
			px(x, 106, 1, 29, 0x86b3c8)
		# Periodensystem
		px(18, 32, 84, 50, 0x333a44); px(20, 34, 80, 46, 0xf4f4f4); write("PSE", 22, 36, 0x333a44)
		var cols := [0xff6b6b, 0xffb347, 0xffe066, 0x7bd389, 0x5bc0eb, 0xb58cf0]
		for r in 6:
			for c in 18:
				if (r == 0 and c > 0 and c < 17) or (r < 3 and r > 0 and c > 1 and c < 12):
					continue
				var ci := 0 if c < 2 else (1 + (c % 2)) if c < 12 else (3 + ((c + r) % 3))
				px(23 + c * 4, 44 + r * 6, 3, 5, cols[ci])
		# Tafel mit Formeln und Atom
		px(116, 32, 108, 56, 0x4a3526); px(119, 35, 102, 50, 0x23463a)
		write("F=MA", 126, 41, 0xf4f4f4); write("H2O", 126, 53, 0x9be7ff); write("E=MC2", 126, 65, 0xffe66d)
		for a in 40:
			var t := a / 40.0 * TAU
			px(round(190 + cos(t) * 18), round(60 + sin(t) * 7), 1, 1, 0xdfe9df)
			px(round(190 + cos(t) * 7), round(60 + sin(t) * 18), 1, 1, 0xdfe9df)
		px(189, 59, 3, 3, 0xff6b6b); px(207, 58, 2, 2, 0xffe066); px(186, 43, 2, 2, 0xffe066)
		px(116, 88, 108, 3, 0x8f5a2e)
		# Regal mit Kolben und Flaschen
		for sy in [60, 84]:
			px(242, sy, 88, 2, 0x8f5a2e); px(246, sy + 2, 2, 4, 0x6b4426); px(324, sy + 2, 2, 4, 0x6b4426)
		var liquids := [0xff6b6b, 0x5bc0eb, 0x7bd389, 0xb58cf0, 0xffe066, 0xff9bd5]
		for i in liquids.size():
			var x := 247 + i * 14
			px(x + 2, 49, 2, 5, 0xeef8ff); px(x + 1, 54, 4, 1, 0xeef8ff); px(x, 55, 6, 5, 0xeef8ff); px(x + 1, 57, 4, 3, liquids[i])
			px(x + 1, 74, 4, 10, liquids[(i + 2) % 6]); px(x + 2, 72, 2, 2, 0x555b66); px(x + 1, 77, 4, 3, 0xf4f4f4)
		# Fenster
		px(344, 30, 62, 60, 0xf4f4f4); px(347, 33, 56, 54, 0x8fd3ff); px(347, 70, 56, 17, 0x7fc4ef)
		px(374, 33, 2, 54, 0xf4f4f4); px(347, 59, 56, 2, 0xf4f4f4); px(353, 40, 12, 4, 0xffffff); px(384, 47, 10, 3, 0xffffff)
		# Abzug
		px(420, 34, 66, 71, 0x9aa3a8); px(423, 37, 60, 40, 0xcfe6f2); px(423, 37, 60, 2, 0x7d868b); px(423, 77, 60, 3, 0x5f676b)
		px(430, 84, 46, 18, 0x848d92); px(434, 90, 3, 3, 0xd23b3b); px(442, 90, 3, 3, 0x3d6fb6)
		px(451, 64, 2, 5, 0xeef8ff); px(449, 69, 6, 6, 0xeef8ff); px(450, 71, 4, 4, 0x7bd389)
		# Skelett „Herr Knochen“
		var b := 0xf4f4f4
		px(510, 103, 17, 2, 0x555555); px(518, 40, 1, 63, 0x555555); px(514, 44, 9, 7, b); px(516, 46, 2, 2, 0x222222); px(520, 46, 2, 2, 0x222222)
		px(516, 51, 5, 2, b); px(518, 53, 1, 22, b)
		for i in 5:
			px(514, 55 + i * 3, 9, 1, b)
		px(512, 55, 1, 16, b); px(524, 55, 1, 16, b); px(515, 75, 7, 3, b); px(515, 78, 1, 24, b); px(521, 78, 1, 24, b)
		px(513, 102, 3, 1, b); px(521, 102, 3, 1, b)
		# Warnschild, Feuerlöscher
		for i in 10:
			px(569 - i, 36 + i, i * 2 + 1, 1, 0xffd23f)
		px(569, 39, 1, 4, 0x222222); px(569, 44, 1, 1, 0x222222)
		px(590, 84, 6, 18, 0xd23b3b); px(591, 80, 4, 4, 0x333333); px(596, 82, 4, 1, 0x333333); px(591, 90, 4, 3, 0xf4f4f4))


func _desk(x: int) -> void:
	px(x + 6, 100, 18, 3, 0xb5763f); px(x + 7, 103, 2, 2, 0x555555); px(x + 21, 103, 2, 2, 0x555555)  # Tisch
	px(x + 26, 97, 8, 2, 0x3d6fb6); px(x + 26, 99, 2, 6, 0x3d6fb6); px(x + 27, 101, 7, 2, 0x3d6fb6)  # Stuhl
	px(x + 10, 98, 6, 2, 0xffffff)  # Heft


func _bench(x: int) -> void:
	px(x, 98, 40, 3, 0x8f5a2e); px(x + 2, 101, 2, 4, 0x555555); px(x + 36, 101, 2, 4, 0x555555)
