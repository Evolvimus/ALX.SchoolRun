// Erzeugt einmalige Karten-Codes.
// Aufruf:  npm run codes -- <anzahl-pro-lehrer> [lehrer01,lehrer02,...]
// Ergebnis in codes-output/:  codes.csv (für den Druck, GEHEIM halten!)  +  insert.sql (für Supabase)
import { randomInt, createHash } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';

const ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
const checkChar = b => { let s = 0; for (let i = 0; i < b.length; i++) s += (ALPHABET.indexOf(b[i]) + 1) * (i + 3); return ALPHABET[s % ALPHABET.length]; };

const perTeacher = Number(process.argv[2] ?? 50);
// Standard: alle 20 Lehrer:innen. Mythische Versionen (z. B. lehrer01m) nur ausdrücklich angeben,
// damit man davon gezielt wenige Karten drucken kann:  npm run codes -- 5 lehrer01m
const ids = process.argv[3]?.split(',') ?? Array.from({ length: 20 }, (_, i) => `lehrer${String(i + 1).padStart(2, '0')}`);

const seen = new Set();
const rows = [];
for (const id of ids) {
  for (let n = 0; n < perTeacher; n++) {
    let body;
    do { body = Array.from({ length: 7 }, () => ALPHABET[randomInt(ALPHABET.length)]).join(''); } while (seen.has(body));
    seen.add(body);
    const raw = body + checkChar(body);
    const code = `ALX-${raw.slice(0, 4)}-${raw.slice(4)}`;
    rows.push({ id, code, hash: createHash('sha256').update(code).digest('hex') });
  }
}

mkdirSync('codes-output', { recursive: true });
writeFileSync('codes-output/codes.csv', 'charakter,code\n' + rows.map(r => `${r.id},${r.code}`).join('\n') + '\n');
writeFileSync('codes-output/insert.sql',
  'insert into public.codes (code_hash, character_id) values\n' +
  rows.map(r => `('${r.hash}','${r.id}')`).join(',\n') + '\non conflict do nothing;\n');
console.log(`${rows.length} Codes für ${ids.length} Charaktere erzeugt -> codes-output/`);
