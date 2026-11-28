extends Control
## Einstellungen als eigener Bildschirm (z. B. --screen=einstellungen); schließt zurück ins Menü.

var params := {}


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	SettingsPanel.open(self).closed.connect(func(): Nav.goto("menu"))
