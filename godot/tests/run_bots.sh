#!/usr/bin/env bash
# Lässt den Testbot jedes Level mit mehreren Figuren durchspielen und meldet, ob alle Level lösbar sind.
# Aufruf aus dem Ordner godot/:   ./tests/run_bots.sh            (Godot muss als "godot" im PATH liegen)
#                                 GODOT=/pfad/zu/godot ./tests/run_bots.sh
set -u
GODOT=${GODOT:-godot}
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --import >/dev/null 2>&1
fail=0
for char in schueler lehrer01 lehrer01m; do
  for level in 0 1 2 3 4; do
    line=$(timeout 240 "$GODOT" --headless --path . -- --fresh --unlock-all --char=$char --level=$level --bot --quit 2>&1 | grep "BOT_RESULT" | tail -1)
    if [[ "$line" == *"result=win"* ]]; then echo "OK      $char  $line"; else echo "FEHLER  $char  level=$level  ${line:-kein Ergebnis}"; fail=1; fi
  done
done
exit $fail
