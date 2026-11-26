class_name CodeFormat
extends RefCounted
## Codeformat der Sammelkarten: ALX-XXXX-XXXX (8 Zeichen, das letzte ist ein Prüfzeichen).
## Ohne verwechselbare Zeichen (0/O, 1/I/L). Das Prüfzeichen fängt nur Tippfehler ab –
## ob ein Code echt und noch unbenutzt ist, entscheidet ausschließlich der Server.
## Muss zu scripts/generate-codes.mjs im Hauptordner passen.

const ALPHABET := "23456789ABCDEFGHJKMNPQRSTUVWXYZ"


static func check_char(body: String) -> String:
	var sum := 0
	for i in body.length():
		sum += (ALPHABET.find(body[i]) + 1) * (i + 3)
	return ALPHABET[sum % ALPHABET.length()]


static func normalize(input: String) -> String:
	var raw := ""
	for ch in input.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			raw += ch
	if raw.begins_with("ALX"):
		raw = raw.substr(3)
	return raw


## Gibt den formatierten Code zurück oder "" bei Tippfehler.
static func validate(input: String) -> String:
	var raw := normalize(input)
	if raw.length() != 8:
		return ""
	for ch in raw:
		if ALPHABET.find(ch) < 0:
			return ""
	if check_char(raw.substr(0, 7)) != raw[7]:
		return ""
	return "ALX-%s-%s" % [raw.substr(0, 4), raw.substr(4)]
