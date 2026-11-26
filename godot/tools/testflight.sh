#!/usr/bin/env bash
# Baut die iOS-App (iPhone + iPad) und lädt sie zu App Store Connect hoch, von wo sie in TestFlight erscheint.
# Läuft NUR auf einem Mac mit Xcode. Einmalige Vorbereitung: siehe README, Abschnitt „iOS und TestFlight“.
#
# Aufruf im Ordner godot/:
#   TEAM_ID=ABCDE12345 ./tools/testflight.sh                       (nur bauen, .ipa danach mit „Transporter“ hochladen)
#   TEAM_ID=ABCDE12345 ASC_KEY_ID=XYZ ASC_ISSUER_ID=uuid ./tools/testflight.sh   (bauen + automatisch hochladen)
#
# Optional: GODOT=/Applications/Godot.app/Contents/MacOS/Godot  BUILD=7 (Buildnummer, sonst Zeitstempel)
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
BUILD=${BUILD:-$(date +%Y%m%d%H%M)}
OUT=build/ios/ALX-SchoolRun.ipa

[[ "$(uname)" == "Darwin" ]] || { echo "Das geht nur auf einem Mac (mit Xcode)."; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode fehlt (App Store) – danach einmal Xcode öffnen und Lizenz bestätigen."; exit 1; }
[[ -x "$GODOT" ]] || { echo "Godot nicht gefunden: $GODOT  (mit GODOT=/pfad/zu/Godot angeben)"; exit 1; }
[[ -n "${TEAM_ID:-}" ]] || { echo "TEAM_ID fehlt (Apple Developer → Membership → Team ID)."; exit 1; }

# Team-ID und Buildnummer in die Exportvorlage schreiben (Buildnummer muss bei jedem Upload größer werden)
sed -i '' -e "s/^application\/app_store_team_id=.*/application\/app_store_team_id=\"$TEAM_ID\"/" \
          -e "/^\[preset.1.options\]/,/^\[preset.2\]/ s/^application\/version=.*/application\/version=\"$BUILD\"/" export_presets.cfg

mkdir -p build/ios
echo "== Godot: Import"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
echo "== Godot: iOS-Export (Build $BUILD) – Godot ruft dabei Xcode zum Signieren auf"
"$GODOT" --headless --path . --export-release "iOS" "$OUT"
[[ -f "$OUT" ]] || { echo "Keine .ipa entstanden. Häufigste Ursache: Signieren – in Xcode unter Settings → Accounts mit der Apple-ID anmelden."; exit 1; }
echo "== Fertig gebaut: $OUT"

if [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" ]]; then
  echo "== Hochladen zu App Store Connect"
  # Der Schlüssel AuthKey_<ASC_KEY_ID>.p8 muss in ~/.appstoreconnect/private_keys/ liegen
  xcrun altool --upload-app --type ios --file "$OUT" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
  echo "== Hochgeladen. Nach 10–30 Minuten Verarbeitung erscheint der Build in App Store Connect unter TestFlight."
else
  echo "== Jetzt die App „Transporter“ (Mac App Store) öffnen, mit der Apple-ID anmelden und $OUT hineinziehen → „Liefern“."
fi
