// Druckvorlage für die Rückseiten der Sammelkarten: QR-Code + Code + Lehrername, 9 Karten (63×88 mm) pro A4-Seite.
//
// Aufruf:   npm run cards                         (liest codes-output/codes.csv)
//           npm run cards -- --csv=andere.csv --base=https://example.org/spiel/ --out=codes-output/karten
//
// Ergebnis in codes-output/ (GEHEIM halten, ist per .gitignore ausgeschlossen):
//   karten-rueckseiten.html  – im Browser öffnen und drucken (100 %, ohne Ränder skalieren)
//   karten-rueckseiten.pdf   – fertiges PDF (wird mit dem vorinstallierten Chromium/Playwright erzeugt, falls vorhanden)
//
// Der QR-Code führt zur Landingpage  <base>code.html?c=ALX-XXXX-XXXX  (siehe web/code.html).
// Die Basis-Adresse ist die GitHub-Pages-Adresse der Browser-Version; ändern mit --base=… oder CARDS_BASE_URL.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { createRequire } from 'node:module';
import QRCode from 'qrcode';

const arg = (name, fallback) => {
  const hit = process.argv.find(a => a.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : fallback;
};
const csvPath = arg('csv', 'codes-output/codes.csv');
let base = arg('base', process.env.CARDS_BASE_URL || 'https://evolvimus.github.io/ALX.SchoolRun/');
if (!base.endsWith('/')) base += '/';
const out = arg('out', 'codes-output/karten-rueckseiten');

// Lehrernamen aus der Spiel-Datenbank (chars.gd); Platzhalter heißen „Lehrer 02“ usw.
const names = {};
try {
  const src = readFileSync('godot/scripts/data/chars.gd', 'utf8');
  for (const m of src.matchAll(/"id":\s*"(\w+)",\s*"name":\s*"([^"]+)"/g)) names[m[1]] = m[2];
} catch { /* ohne Namen geht es auch */ }
const nameOf = id => names[id] || id.replace(/^lehrer(\d+)$/, 'Lehrer $1');

const rows = readFileSync(csvPath, 'utf8').trim().split(/\r?\n/).slice(1)
  .map(l => l.split(',').map(s => s.trim())).filter(r => r.length >= 2 && r[1]);
if (!rows.length) { console.error(`Keine Codes in ${csvPath}`); process.exit(1); }

const esc = s => s.replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const cards = [];
for (const [id, code] of rows) {
  const url = `${base}code.html?c=${encodeURIComponent(code)}`;
  const svg = await QRCode.toString(url, { type: 'svg', errorCorrectionLevel: 'M', margin: 0, color: { dark: '#0d1024', light: '#ffffff' } });
  cards.push(`
    <div class="card">
      <div class="head"><span class="tag">ALX</span><span class="title">SCHOOLRUN</span></div>
      <div class="qr">${svg}</div>
      <div class="code">${esc(code)}</div>
      <div class="name">${esc(nameOf(id))}</div>
      <div class="how">Scanne mich oder gib den Code im Spiel unter „Code einlösen“ ein.</div>
      <div class="once">Nur einmal gültig</div>
    </div>`);
}

const pages = [];
for (let i = 0; i < cards.length; i += 9) pages.push(`<section class="page">${cards.slice(i, i + 9).join('')}</section>`);

const html = `<!doctype html>
<html lang="de"><head><meta charset="utf-8"><title>ALX SchoolRun – Karten-Rückseiten</title>
<style>
  @page { size: A4; margin: 0; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: "DejaVu Sans", Arial, sans-serif; color: #0d1024; }
  .page { width: 210mm; height: 297mm; padding: 13.5mm 10.5mm; display: grid;
          grid-template-columns: repeat(3, 63mm); grid-auto-rows: 88mm; gap: 0; page-break-after: always; }
  .card { position: relative; width: 63mm; height: 88mm; padding: 4mm; display: flex; flex-direction: column; align-items: center;
          border: 0.2mm dashed #b8b8c8; background: #fff; }
  /* Schnittmarken an den Ecken */
  .card::before, .card::after { content: ""; position: absolute; width: 4mm; height: 4mm; border-color: #000; border-style: solid; }
  .card::before { top: -0.1mm; left: -0.1mm; border-width: 0.25mm 0 0 0.25mm; }
  .card::after { bottom: -0.1mm; right: -0.1mm; border-width: 0 0.25mm 0.25mm 0; }
  .head { display: flex; gap: 1.5mm; align-items: center; margin-bottom: 2.5mm; }
  .tag { font-weight: 700; font-size: 7pt; border: 0.4mm solid #b8860b; color: #b8860b; border-radius: 1.5mm; padding: 0 1.2mm; }
  .title { font-weight: 800; font-size: 10pt; letter-spacing: 0.6pt; }
  .qr { width: 38mm; height: 38mm; padding: 2mm; border: 0.6mm solid #ffcc33; border-radius: 2.5mm; }
  .qr svg { width: 100%; height: 100%; display: block; }
  .code { font-family: "DejaVu Sans Mono", "Courier New", monospace; font-weight: 700; font-size: 12.5pt; letter-spacing: 0.4pt;
          margin-top: 3mm; padding: 1.2mm 2.2mm; background: #f4f1e6; border-radius: 1.5mm; }
  .name { font-size: 8.5pt; font-weight: 700; margin-top: 2mm; }
  .how { font-size: 6.5pt; text-align: center; color: #3a3f66; margin-top: 1.8mm; line-height: 1.35; }
  .once { position: absolute; bottom: 3mm; font-size: 5.5pt; color: #8d93b8; letter-spacing: 0.3pt; text-transform: uppercase; }
  @media screen { body { background: #ccc; } .page { background: #fff; margin: 10mm auto; box-shadow: 0 2px 10px rgba(0,0,0,.3); } }
</style></head>
<body>${pages.join('\n')}</body></html>`;

mkdirSync(dirname(out), { recursive: true });
writeFileSync(`${out}.html`, html);
console.log(`${cards.length} Karten auf ${pages.length} Seite(n) -> ${out}.html`);

// PDF mit Chromium (Playwright), falls installiert
try {
  // require() findet auch global installiertes Playwright (NODE_PATH), import() nicht
  const { chromium } = createRequire(import.meta.url)('playwright');
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'load' });
  await page.pdf({ path: `${out}.pdf`, format: 'A4', printBackground: true, preferCSSPageSize: true });
  await browser.close();
  console.log(`PDF -> ${out}.pdf`);
} catch (e) {
  console.log('Kein PDF erzeugt (Playwright/Chromium fehlt) – die HTML-Datei im Browser öffnen und drucken.');
}
