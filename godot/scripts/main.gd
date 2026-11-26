extends Node
## Einstieg: startet das Menü (oder direkt ein Level, siehe Startoptionen in nav.gd).


func _ready() -> void:
	Nav.start.call_deferred()
	var restored: Array = await Backend.fetch_unlocks()
	for id in restored:
		Save.unlock(id)
