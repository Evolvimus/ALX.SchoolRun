class_name LevelDef
extends Node2D
## Ein Level als Szene. So baust du ein neues Level im Godot-Editor:
##   1. Eine vorhandene Levelszene in levels/ duplizieren.
##   2. Den Knoten „Tiles“ auswählen und unten im TileMap-Fenster Kacheln malen (Legende: siehe README).
##      Das Level beginnt bei Zelle (0, 0) oben links. Die untersten drei Zeilen sind normalerweise Boden.
##   3. Hinweistexte: Label-Knoten unter „Hints“ anlegen und an die gewünschte Stelle schieben.
##      Platzhalter: {LAUFEN} {SPRINGEN} {HOCH} {HIEB} {WAFFE}
##   4. Die Szene in scripts/data/levels.gd in die Liste SCENES eintragen.

## Name, der im Spiel angezeigt wird
@export var title := "Neues Level"
## Hintergrundbild
@export_enum("bg-school", "bg-gym", "bg-lab") var background := "bg-school"
## Zielzeit in Sekunden für die Medaille „Unter Zielzeit“
@export var par_seconds := 60.0
