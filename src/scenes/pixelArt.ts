// Pixel-Art-Grafiken, prozedural gezeichnet (1 Pixel = 3x3 Bildschirmpixel).
import Phaser from 'phaser';
import { ALL_CHARACTERS, Look } from '../data/characters';

export const P = 3;
type G = Phaser.GameObjects.Graphics;

let S = P; // aktuelle Pixelgröße beim Zeichnen
const px = (g: G, x: number, y: number, w: number, h: number, c: number, a = 1) => { g.fillStyle(c, a).fillRect(x * S, y * S, w * S, h * S); };

function sprite(g: G, rows: string[], pal: Record<string, number>, ox = 0, oy = 0) {
  rows.forEach((r, y) => [...r].forEach((ch, x) => { if (pal[ch] !== undefined) px(g, ox + x, oy + y, 1, 1, pal[ch]); }));
}
function blob(g: G, cx: number, cy: number, r: number, c: number) {
  for (let y = -r; y <= r; y++) { const w = Math.round(Math.sqrt(r * r - y * y)); px(g, cx - w, cy + y, w * 2 + 1, 1, c); }
}
function line(g: G, x0: number, y0: number, x1: number, y1: number, c: number, t = 1) {
  const n = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0), 1);
  for (let i = 0; i <= n; i++) px(g, Math.round(x0 + (x1 - x0) * i / n), Math.round(y0 + (y1 - y0) * i / n), t, t, c);
}

// Mini-Pixelschrift (3x5) für Tafel und Poster
const FONT: Record<string, string[]> = {
  A: ['.#.', '#.#', '###', '#.#', '#.#'], B: ['##.', '#.#', '##.', '#.#', '##.'], I: ['###', '.#.', '.#.', '.#.', '###'],
  '2': ['##.', '..#', '.#.', '#..', '###'], '0': ['###', '#.#', '#.#', '#.#', '###'], '6': ['###', '#..', '###', '#.#', '###'],
  E: ['###', '#..', '##.', '#..', '###'], M: ['#.#', '###', '###', '#.#', '#.#'], C: ['###', '#..', '#..', '#..', '###'],
  '=': ['...', '###', '...', '###', '...'], X: ['#.#', '#.#', '.#.', '#.#', '#.#'], '+': ['...', '.#.', '###', '.#.', '...'],
  T: ['###', '.#.', '.#.', '.#.', '.#.'],
  L: ['#..', '#..', '#..', '#..', '###'], F: ['###', '#..', '##.', '#..', '#..'], H: ['#.#', '#.#', '###', '#.#', '#.#'],
  O: ['###', '#.#', '#.#', '#.#', '###'], P: ['##.', '#.#', '##.', '#..', '#..'], S: ['.##', '#..', '.#.', '..#', '##.'], '8': ['###', '#.#', '###', '#.#', '###'], '1': ['.#.', '##.', '.#.', '.#.', '###'], ' ': ['...', '...', '...', '...', '...'],
};
function write(g: G, text: string, x: number, y: number, c: number) {
  [...text].forEach((ch, i) => sprite(g, FONT[ch] ?? FONT[' '], { '#': c }, x + i * 4, y));
}

const HEAD = [
  '...HHHHHH...', '..HHHHHHHH..', '.HHHHHHHHHH.', '.HHSSSSSSHH.', '.HSSSSSSSSH.', '..SEESSEES..',
  '..SSSSSSSS..', '..SSSMMSSS..', '...SSSSSS...',
];
const TORSO = ['..BBBDDBBB..', '.BBBBDDBBBB.', 'SBBBBBBBBBBS', 'SSBBBBBBBBSS', '.SBBBBBBBBS.', '..BBBBBBBB..'];
const TORSO_JUMP = ['S.BBBDDBBB.S', 'SBBBBDDBBBBS', '.BBBBBBBBBB.', '..BBBBBBBB..', '..BBBBBBBB..', '..BBBBBBBB..'];
const LEGS: Record<string, string[]> = {
  '': ['..PPPPPPPP..', '..PPP..PPP..', '..PPP..PPP..', '.KKKK..KKKK.', '.KKKK..KKKK.'],
  '-w1': ['..PPPPPPPP..', '..PPP..PPP..', '..PPP.KKKK..', '.KKKK.......', '.KKKK.......'],
  '-w2': ['..PPPPPPPP..', '..PPP..PPP..', '.KKKK..PPP..', '.......KKKK.', '.......KKKK.'],
  '-j': ['..PPPPPPPP..', '.PPPP..PPPP.', '.KKK....KKK.', '............', '............'],
};
const HAIR = [0x3b2414, 0x8a5a2b, 0xd9b44a, 0x1a1a1a, 0xa0a0a0, 0xb5452b];

function darken(c: number, f = 0.7) {
  const r = (c >> 16) & 255, gg = (c >> 8) & 255, b = c & 255;
  return (Math.floor(r * f) << 16) | (Math.floor(gg * f) << 8) | Math.floor(b * f);
}

// Ginkgoblatt: breiter Fächer mit Schlitz in der Mitte und langem Stiel
const LEAF = [
  '.wwwww.wwwww.', 'wyyyyy.yyyyyw', 'yyyyyydyyyyyy', 'yydyyydyyydyy', '.yydyydyydyy.', '..yydydydyy..',
  '...yydddyy...', '....yydyy....', '.....ydy.....', '......s......', '......s......', '.....ss......',
];
const GOLD = { y: 0xffc928, w: 0xffe98a, d: 0xd99a00, s: 0x8a6a1a };
const GREEN = { y: 0x6cc04a, w: 0xa6e07a, d: 0x3f8f2e, s: 0x4a6a1a };
const WILT = { y: 0x5e5038, w: 0x6f6046, d: 0x40351f, s: 0x3a2f1c };

/**
 * Detailfigur in dreifacher Auflösung (36x60 statt 12x20) für Lehrer:innen mit eigenem Aussehen.
 * f = '' (stehen), '-w1'/'-w2' (laufen), '-j' (springen)
 */
function drawDetailed(g: G, l: Look, f: string) {
  const R = (x: number, y: number, w: number, h: number, c: number) => px(g, x, y, w, h, c);
  const skin = l.skin, skinD = darken(l.skin, 0.86), hair = l.hair, hairD = darken(l.hair, 0.7);
  const jump = f === '-j';

  // --- Zopf (hinter Schulter und Arm, deshalb zuerst)
  if (l.ponytail) {
    R(5, 8, 3, 9, hair); R(4, 15, 3, 12, hair); R(5, 26, 2, 5, hair); R(6, 30, 1, 3, hairD);
    R(4, 15, 1, 12, hairD); R(5, 9, 3, 1, 0x1a1a1a);
  }

  // --- Beine und Schuhe
  const leg = (x: number, len: number, shoeDx: number) => {
    R(x, 45, 7, len, l.pants); R(x, 45, 1, len, darken(l.pants, 0.8)); R(x + 6, 45, 1, len, darken(l.pants, 0.8));
    R(x - 1 + shoeDx, 45 + len, 9, 4, l.shoes); R(x - 1 + shoeDx, 48 + len, 9, 1, darken(l.shoes, 0.6));
  };
  R(10, 44, 16, 3, l.pants);
  if (jump) { leg(9, 6, -1); leg(20, 6, 1); }
  else if (f === '-w1') { leg(8, 11, -1); leg(20, 8, 2); }
  else if (f === '-w2') { leg(11, 8, 2); leg(21, 11, 1); }
  else { leg(10, 11, 0); leg(19, 11, 0); }

  // --- Arme (Hemdärmel) und Hände
  if (jump) {
    R(3, 22, 5, 9, l.shirt); R(28, 22, 5, 9, l.shirt); R(3, 22, 1, 9, darken(l.shirt)); R(32, 22, 1, 9, darken(l.shirt));
    R(5, 28, 5, 3, l.shirt); R(26, 28, 5, 3, l.shirt);
    R(3, 18, 4, 4, skin); R(29, 18, 4, 4, skin);
  } else {
    const sw = f === '-w1' ? 1 : f === '-w2' ? -1 : 0;
    R(5, 28, 5, 11 + sw, l.shirt); R(26, 28, 5, 11 - sw, l.shirt); R(5, 28, 1, 11 + sw, darken(l.shirt)); R(30, 28, 1, 11 - sw, darken(l.shirt));
    R(5, 39 + sw, 4, 4, skin); R(27, 39 - sw, 4, 4, skin); R(5, 42 + sw, 4, 1, skinD); R(27, 42 - sw, 4, 1, skinD);
  }

  // --- Oberkörper: Strickweste mit V-Ausschnitt, Hemd, Krawatte, Gürtel
  R(10, 27, 16, 16, l.vest); R(10, 27, 1, 16, darken(l.vest)); R(25, 27, 1, 16, darken(l.vest));
  for (let y = 28; y < 43; y += 2) for (let x = 11 + (y % 4 === 0 ? 1 : 0); x < 25; x += 2) R(x, y, 1, 1, darken(l.vest, 0.85));
  for (let i = 0; i < 8; i++) R(14 + Math.ceil(i / 2), 27 + i, 8 - Math.ceil(i / 2) * 2, 1, l.shirt); // V-Ausschnitt
  R(13, 27, 3, 2, darken(l.shirt, 1.3)); R(20, 27, 3, 2, darken(l.shirt, 1.3)); // Kragen
  R(16, 27, 4, 2, l.tie); R(17, 29, 2, 7, l.tie); R(17, 29, 1, 7, darken(l.tie, 0.85)); R(17, 31, 2, 1, darken(l.tie, 0.7)); R(17, 34, 2, 1, darken(l.tie, 0.7));
  R(18, 37, 1, 1, 0x2a2a2a); R(18, 40, 1, 1, 0x2a2a2a); // Knöpfe
  R(10, 43, 16, 2, l.belt); R(10, 44, 16, 1, darken(l.belt)); R(17, 43, 2, 2, 0xd9c070);

  // --- Hals
  R(14, 24, 8, 3, skinD);

  // --- Kopf (bewusst groß, damit man das Gesicht erkennt): oben kahl, Haare nur seitlich und hinten, nach hinten gebunden
  R(13, 0, 10, 1, skin); R(11, 1, 14, 1, skin); R(10, 2, 16, 1, skin); R(9, 3, 18, 3, skin); R(8, 6, 20, 15, skin);
  R(9, 21, 18, 1, skin); R(10, 22, 16, 1, skin); R(12, 23, 12, 1, skin); R(14, 24, 8, 1, skin);
  R(7, 13, 1, 4, skin); R(28, 13, 1, 4, skin); R(7, 16, 1, 1, skinD); R(28, 16, 1, 1, skinD); // Ohren
  // Haare: straff nach hinten gekämmt, hoher Haaransatz mit leichten Geheimratsecken
  R(13, 0, 10, 1, hair); R(11, 1, 14, 1, hair); R(10, 2, 16, 1, hair); R(9, 3, 3, 1, hair); R(24, 3, 3, 1, hair); R(14, 3, 8, 1, hair);
  R(16, 4, 4, 1, hairD); R(12, 3, 2, 1, hairD); R(22, 3, 2, 1, hairD);                 // Haaransatz
  for (const x of [13, 16, 19, 22]) R(x, 0, 1, 3, hairD);                             // gekämmte Strähnen
  R(8, 3, 1, 3, hair); R(27, 3, 1, 3, hair); R(7, 5, 2, 8, hair); R(27, 5, 2, 8, hair); // Seiten
  R(9, 4, 1, 6, hairD); R(26, 4, 1, 6, hairD);
  // Augenbrauen
  R(11, 8, 5, 1, darken(skin, 0.7)); R(20, 8, 5, 1, darken(skin, 0.7));
  // Brille: dünnes Gestell mit abgerundeten Ecken, durchsichtige Gläser, Augen dahinter
  const lens = l.lens ?? 0xf8dcc4;
  for (const x of [9, 19]) {
    R(x + 1, 11, 6, 4, lens);                                   // Glas
    R(x + 1, 10, 6, 1, l.glasses); R(x + 1, 15, 6, 1, l.glasses); // oben, unten
    R(x, 11, 1, 4, l.glasses); R(x + 7, 11, 1, 4, l.glasses);     // links, rechts
    R(x + 2, 12, 4, 2, 0xffffff); R(x + 3, 12, 2, 2, 0x1a1a2e);   // Auge
    R(x + 5, 11, 1, 1, 0xffffff);                                // Lichtreflex
  }
  R(17, 12, 2, 1, l.glasses); R(8, 12, 1, 1, l.glasses); R(27, 12, 1, 1, l.glasses); // Steg und Bügel
  // Nase
  R(18, 14, 1, 4, skinD); R(16, 18, 4, 1, skinD);
  // Wangen leicht gerötet, Lächeln, kleiner Kinnbart
  R(9, 17, 3, 2, darken(skin, 0.93)); R(24, 17, 3, 2, darken(skin, 0.93));
  R(13, 19, 1, 1, 0x8a4038); R(22, 19, 1, 1, 0x8a4038); R(14, 20, 8, 1, 0x8a4038); R(15, 20, 6, 1, 0xf4ece4); R(15, 21, 6, 1, 0xb5605a);
  const beard = darken(l.stubble, 0.72);
  R(16, 22, 4, 1, l.stubble); R(15, 23, 6, 1, beard); R(16, 24, 4, 1, beard); R(17, 25, 2, 1, beard);
}

export function makePixelTextures(scene: Phaser.Scene) {
  const g = scene.add.graphics();
  const gen = (key: string, w: number, h: number, draw: () => void, size = P) => {
    S = size; g.clear(); draw(); g.generateTexture(key, w * size, h * size); S = P;
  };

  // ---- Spielfiguren (Platzhalter) mit Lauf- und Sprungbild ----
  ALL_CHARACTERS.forEach((c, i) => {
    if (c.look) {
      const l = c.look;
      for (const f of ['', '-w1', '-w2', '-j']) gen(`char-${c.id}${f}`, 36, 60, () => drawDetailed(g, l, f), 1);
      return;
    }
    const pal = { H: HAIR[i % HAIR.length], S: 0xf2c49b, E: 0x1a1a2e, M: 0xb5524a, B: c.color, D: darken(c.color), P: 0x2e3a5c, K: 0x222222 };
    for (const f of Object.keys(LEGS)) gen(`char-${c.id}${f}`, 12, 20, () => sprite(g, [...HEAD, ...(f === '-j' ? TORSO_JUMP : TORSO), ...LEGS[f]], pal));
  });
  // Hammer (Herr Hammer) und goldener Hammer (mythische Version)
  const hammer = (handle: number, head: number, shine: number) => {
    px(g, 0, 3, 12, 2, handle); px(g, 0, 4, 12, 1, darken(handle));
    px(g, 11, 0, 5, 8, head); px(g, 11, 0, 5, 1, shine); px(g, 15, 0, 1, 8, darken(head)); px(g, 11, 7, 5, 1, darken(head));
  };
  gen('hammer', 16, 8, () => hammer(0x8a5a2b, 0x8c8f99, 0xc9ccd6));
  gen('hammer-gold', 16, 8, () => hammer(0x5a3a22, 0xf2b61c, 0xfff0a0));
  gen('ruler', 16, 3, () => { px(g, 0, 0, 16, 3, 0xffd23f); px(g, 0, 2, 16, 1, 0xc99a14); for (let i = 1; i < 16; i += 2) px(g, i, 0, 1, i % 4 === 1 ? 2 : 1, 0x6b4a00); });

  // ---- Ginkgo: Schullogo als roter Faden ----
  gen('leaf', 13, 12, () => sprite(g, LEAF, GOLD));
  gen('leaf-s', 13, 12, () => sprite(g, LEAF, GOLD), 2);
  gen('leaf-green', 13, 12, () => sprite(g, LEAF, GREEN));
  gen('leaf-wilt', 13, 12, () => sprite(g, LEAF, WILT));
  gen('leaf-logo', 13, 12, () => sprite(g, LEAF, GOLD), 8);
  const pot = () => { px(g, 3, 15, 9, 2, 0xd9764a); px(g, 4, 17, 7, 5, 0xb5522e); px(g, 4, 17, 1, 5, 0x8f3f22); px(g, 5, 15, 5, 1, 0x3a2a1a); };
  gen('seed-0', 15, 22, () => { pot(); px(g, 7, 12, 1, 3, 0x4a8a2e); px(g, 6, 11, 1, 1, 0x6cc04a); px(g, 8, 12, 1, 1, 0x6cc04a); });
  gen('seed-1', 15, 22, () => {
    pot(); px(g, 7, 4, 1, 11, 0x4a8a2e);
    sprite(g, ['.g.g.', 'ggggg', '.ggg.', '..g..'], { g: 0x6cc04a }, 1, 6);
    sprite(g, ['.g.g.', 'ggggg', '.ggg.', '..g..'], { g: 0x8ed45f }, 9, 8);
    sprite(g, ['.y.y.', 'yyyyy', '.yyy.', '..y..'], { y: 0xffc928 }, 5, 0);
  });
  // Großer Ginkgo im Kübel (Levelziel): kahl und golden
  const tree = (gold: boolean) => {
    px(g, 20, 64, 24, 3, 0x9a9aa2); px(g, 22, 67, 20, 11, 0x74747c); px(g, 22, 67, 2, 11, 0x5c5c64); px(g, 24, 64, 16, 1, 0x3a2a1a);
    px(g, 30, 28, 4, 36, 0x6b4a2a); px(g, 30, 28, 1, 36, 0x8a6238); px(g, 33, 40, 1, 24, 0x4f3620);
    line(g, 31, 42, 16, 26, 0x6b4a2a, 2); line(g, 32, 38, 46, 22, 0x6b4a2a, 2); line(g, 31, 30, 27, 12, 0x6b4a2a, 2);
    line(g, 33, 30, 39, 10, 0x6b4a2a, 2); line(g, 20, 30, 11, 30, 0x6b4a2a); line(g, 42, 26, 53, 28, 0x6b4a2a);
    const crown: [number, number, number][] = [[16, 22, 9], [46, 18, 10], [27, 10, 9], [39, 8, 8], [31, 20, 11], [10, 31, 6], [54, 28, 6], [22, 31, 7], [42, 30, 7]];
    if (!gold) { crown.forEach(([x, y, r], i) => { if (i % 2 === 0) blob(g, x, y - 1, 2, 0x5aa03c); px(g, x + r - 3, y + 2, 2, 2, 0x7d9a4a); }); return; }
    crown.forEach(([x, y, r]) => blob(g, x, y + 1, r, 0xc98f10));
    crown.forEach(([x, y, r]) => blob(g, x, y, r - 1, 0xf2b61c));
    crown.forEach(([x, y, r]) => blob(g, x - 2, y - 2, Math.max(2, r - 4), 0xffd84a));
    for (let i = 0; i < 70; i++) px(g, 6 + (i * 29) % 52, 3 + (i * 17) % 34, 1, 1, i % 2 ? 0xfff0a0 : 0xd99a00);
  };
  gen('tree-bare', 64, 78, () => tree(false));
  gen('tree-gold', 64, 78, () => tree(true));

  // ---- Gelände ----
  const dark = (top: boolean) => {
    px(g, 0, 0, 15, 15, 0x26262b);
    for (let i = 0; i < 14; i++) px(g, (i * 7 + (top ? 3 : 0)) % 15, (i * 11 + 4) % 15, 2, 1, i % 2 ? 0x34343b : 0x1b1b1f);
    if (top) { px(g, 0, 0, 15, 2, 0xd9652b); px(g, 0, 2, 15, 1, 0x8a3a14); px(g, 0, 0, 15, 1, 0xf08a4b); }
  };
  gen('ground', 15, 15, () => dark(true));
  gen('under', 15, 15, () => dark(false));
  gen('platform', 15, 6, () => { px(g, 0, 0, 15, 6, 0x8f5a2e); px(g, 0, 0, 15, 2, 0xd69a5c); px(g, 0, 5, 15, 1, 0x4a2c17); px(g, 1, 3, 2, 1, 0x6b4426); });
  gen('box', 15, 15, () => {
    px(g, 0, 0, 15, 15, 0xd9a05b); px(g, 0, 0, 15, 2, 0xd9652b);
    for (const y of [5, 9, 13]) px(g, 0, y, 15, 1, 0x9a6a33);
    px(g, 0, 2, 1, 13, 0xb5803f); px(g, 14, 2, 1, 13, 0x9a6a33);
  });
  // Bücherregal
  gen('shelf', 15, 15, () => {
    px(g, 0, 0, 15, 15, 0x5a3820); px(g, 0, 0, 15, 2, 0xb5763f); px(g, 0, 8, 15, 1, 0xb5763f); px(g, 0, 14, 15, 1, 0x3d2513);
    const books = [0xd23b3b, 0x3d6fb6, 0xe0a23b, 0x4fa36b, 0x8a5fc4, 0xf4f4f4, 0x2a8a8a];
    for (let i = 0; i < 7; i++) { px(g, i * 2 + (i > 3 ? 1 : 0), 3, 2, 5, books[i]); px(g, i * 2 + 1, 9 + (i % 2), 2, 5 - (i % 2), books[(i + 3) % 7]); }
    px(g, 1, 4, 1, 1, 0xffffff); px(g, 9, 5, 1, 1, 0x222222);
  });
  // Labortisch
  gen('lab', 15, 15, () => {
    px(g, 0, 0, 15, 15, 0xe4e8ea); px(g, 0, 0, 15, 3, 0x2f3640); px(g, 0, 0, 15, 1, 0x4a5563); px(g, 0, 3, 15, 1, 0x9aa3a8);
    px(g, 7, 4, 1, 11, 0xb9c1c6); px(g, 3, 8, 2, 1, 0x7d868b); px(g, 10, 8, 2, 1, 0x7d868b); px(g, 0, 14, 15, 1, 0x9aa3a8);
  });
  gen('crate', 15, 15, () => {
    px(g, 0, 0, 15, 15, 0xb8834c); px(g, 0, 0, 15, 1, 0xd9a86c); px(g, 0, 14, 15, 1, 0x7a5228); px(g, 14, 0, 1, 15, 0x7a5228);
    px(g, 6, 0, 3, 15, 0xd9c7a0); write(g, 'ABI', 2, 8, 0x8a2b2b);
  });
  gen('mat', 15, 5, () => { px(g, 0, 0, 15, 5, 0x2d6fd6); px(g, 0, 0, 15, 1, 0x5a97f0); px(g, 0, 4, 15, 1, 0x1b4a99); px(g, 0, 0, 1, 5, 0x1b4a99); px(g, 14, 0, 1, 5, 0x1b4a99); });
  gen('spikes', 15, 15, () => {
    for (let i = 0; i < 3; i++) { const x = i * 5; px(g, x + 2, 9, 1, 5, 0xd8d8d8); px(g, x, 12, 5, 2, 0xd23b3b); px(g, x + 1, 11, 3, 1, 0xff6b6b); }
  });

  // ---- Gegner ----
  const MOUSE = { g: 0x8d8d96, l: 0xb4b4be, d: 0x62626a, w: 0xffffff, k: 0x1a1a1a, p: 0xff9bb0 };
  gen('mouse-0', 11, 8, () => sprite(g, ['..d.gggl...', '.ggglgggg..', 'pgggggglggd', 'gwkggggggggd', 'ggggglggggg', '.ggggggggl.', '..g..g..g..'].map(r => r.slice(0, 11)), MOUSE, 0, 1));
  gen('mouse-1', 11, 8, () => sprite(g, ['...dgggl...', '.ggglgggg.d', 'pgggggglggd', 'gwkgggggggg', 'ggggglggggg', '.ggggggggl.', '.g..g..g...'], MOUSE, 0, 0));
  gen('plane', 14, 7, () => sprite(g, ['#.............', '###...........', '#####.........', '##############', '.#########....', '..######......', '...##.........'], { '#': 0xf4f4f4 }));
  gen('paperball', 6, 6, () => sprite(g, ['.wwww.', 'wwdwww', 'wdwwdw', 'wwwdww', 'wwdwww', '.wwww.'], { w: 0xf4f4f4, d: 0xbdbdbd }));
  // Bücherwurm mit Brille
  gen('worm', 9, 18, () => sprite(g, [
    '..ggggg..', '.ggggggg.', 'kkkkgkkkk', 'kwwkgkwwk', 'kkkkgkkkk', '.ggggggg.', '.ggmmmgg.', '..ggggg..',
    '.ggggggg.', '.glllllg.', '.ggggggg.', '.glllllg.', '.ggggggg.', '.glllllg.', '.ggggggg.', '.glllllg.', '.ggggggg.', '.glllllg.',
  ], { g: 0x9bc53d, l: 0xcfe57a, k: 0x222222, w: 0xdff4ff, m: 0x5a2a2a }));
  gen('hole', 13, 3, () => { px(g, 1, 0, 11, 3, 0x0c0c0e); px(g, 0, 1, 13, 1, 0x0c0c0e); px(g, 2, 0, 2, 1, 0xf4f4f4); px(g, 9, 2, 2, 1, 0xd9c7a0); });
  // Laubbläser (Düse zeigt nach links)
  const blower = (f: number, broken = false) => {
    const body = broken ? 0x4a3a30 : 0xe8742a, dk = broken ? 0x2a2420 : 0xa84a12;
    px(g, 8, 3 + f, 8, 7, body); px(g, 8, 9 + f, 8, 1, dk); px(g, 10, 1 + f, 5, 2, 0x222222); px(g, 11, 5 + f, 3, 3, broken ? 0x333333 : 0xffd23f);
    px(g, 3, 5 + f, 5, 4, 0x555b66); px(g, 0, 4 + f, 3, 6, 0x7d8590); px(g, 0, 4 + f, 1, 6, 0x222222);
    px(g, 9, 10, 2, 1, 0x222222); px(g, 13, 10, 2, 1, 0x222222);
  };
  gen('blower-0', 16, 11, () => blower(0));
  gen('blower-1', 16, 11, () => blower(-1));
  gen('blower-x', 16, 11, () => blower(0, true));
  gen('wind', 8, 1, () => { px(g, 0, 0, 8, 1, 0xffffff, 0.75); });
  // Hufeisenmagnet (Öffnung nach unten)
  gen('magnet', 13, 12, () => {
    px(g, 2, 0, 9, 4, 0xd23b3b); px(g, 1, 1, 11, 3, 0xd23b3b); px(g, 0, 2, 4, 7, 0xd23b3b); px(g, 9, 2, 4, 7, 0xd23b3b);
    px(g, 3, 1, 6, 1, 0xff7b7b); px(g, 0, 9, 4, 3, 0xdcdfe4); px(g, 9, 9, 4, 3, 0xdcdfe4); px(g, 0, 11, 4, 1, 0x9aa3a8); px(g, 9, 11, 4, 1, 0x9aa3a8);
  });
  // Bunsenbrenner + Flamme
  gen('burner', 9, 8, () => { px(g, 3, 0, 3, 6, 0xb9c1c6); px(g, 3, 0, 1, 6, 0xe4e8ea); px(g, 2, 3, 5, 1, 0x7d868b); px(g, 0, 6, 9, 2, 0x2f3640); px(g, 7, 5, 2, 1, 0x3d6fb6); });
  const flame = (f: number) => {
    for (let y = 0; y < 30; y++) {
      const t = y / 29, half = Math.min(3, Math.round(t < 0.3 ? t * 10 : 3 - (t > 0.85 ? (t - 0.85) * 10 : 0)));
      const wob = Math.round(Math.sin(y * 0.8 + f * 2.4) * (1 - t) * 1.2);
      const outer = t < 0.45 ? 0xff7a1a : t < 0.8 ? 0xffb52e : 0x4aa8ff, inner = t < 0.45 ? 0xffd23f : t < 0.8 ? 0xfff0a0 : 0xbfe6ff;
      px(g, 3 - half + wob, y, half * 2 + 1, 1, outer);
      if (half > 1) px(g, 4 - half + wob, y, half * 2 - 1, 1, inner);
    }
  };
  gen('flame-0', 7, 30, () => flame(0));
  gen('flame-1', 7, 30, () => flame(1));
  // Raupe (Blattdieb)
  const CAT = { g: 0x7ac74f, d: 0x4f9a2e, k: 0x2a2a1a, w: 0xffffff };
  gen('cat-0', 10, 5, () => sprite(g, ['..........', 'kk.gg.gg..', 'kwggdggdgg', 'kkggggdggg', '.d..d..d.d'], CAT));
  gen('cat-1', 10, 5, () => sprite(g, ['....gg....', 'kk.gddg...', 'kwgg..gggg', 'kkgg..dggg', '.d.d...d.d'], CAT));
  gen('ball', 8, 8, () => sprite(g, ['..oooo..', '.ookooo.', 'oookoooo', 'kkkkkkkk', 'oookoooo', 'oookoooo', '.ookooo.', '..oooo..'], { o: 0xe8742a, k: 0x5a2a0c }));

  // ---- Effekte / Bedienung ----
  gen('dot', 1, 1, () => px(g, 0, 0, 1, 1, 0xffffff));
  gen('touch', 30, 30, () => { g.fillStyle(0xffffff, 0.22).fillCircle(45, 45, 45); });
  makeBackground(g);
  makeGym(g);
  makeLab(g);
  g.destroy();
}

/** 640x135 Pixel: Klassenzimmer + Schulflur, wird horizontal gekachelt. */
function makeBackground(g: G) {
  g.clear();
  const WALL = 0xe9dcb5, WALL2 = 0xd9c99c;
  px(g, 0, 0, 640, 135, WALL);
  for (let x = 0; x < 640; x += 8) px(g, x, 10, 1, 95, WALL2);           // Tapetenstreifen
  px(g, 0, 0, 640, 10, 0xbfb59a); px(g, 0, 9, 640, 1, 0x8f866c);       // Decke
  px(g, 0, 105, 640, 30, 0x6f9a86); px(g, 0, 105, 640, 2, 0x4e7362);   // Wandfliesen unten
  for (let x = 0; x < 640; x += 10) px(g, x, 107, 1, 28, 0x5f8a76);
  for (const x of [40, 200, 360, 520]) { px(g, x, 10, 50, 3, 0xffffff); px(g, x, 13, 50, 1, 0xcfe9ff); } // Neonröhren

  // ---- Klassenzimmer (0-320) ----
  px(g, 18, 30, 136, 62, 0x6b4426); px(g, 21, 33, 130, 56, 0x2f5d3a);  // Tafel
  write(g, 'ABI 2026', 30, 40, 0xf4f4f4); write(g, 'E=MC2', 30, 52, 0xf4f4f4); write(g, '1+1=2', 30, 64, 0xffe66d);
  px(g, 95, 45, 40, 1, 0xdfe9df); px(g, 95, 45, 1, 25, 0xdfe9df); px(g, 96, 66, 6, 1, 0xdfe9df); // Koordinatensystem
  for (let i = 0; i < 6; i++) px(g, 98 + i * 6, 64 - i * 3, 2, 2, 0xff9bd5);
  px(g, 18, 92, 136, 3, 0x8f5a2e); px(g, 40, 90, 6, 2, 0xffffff); px(g, 55, 90, 8, 2, 0xffe066); // Kreideablage
  g.fillStyle(0x333333).fillCircle(175 * P, 42 * P, 9 * P); g.fillStyle(0xffffff).fillCircle(175 * P, 42 * P, 8 * P); // Uhr
  px(g, 175, 36, 1, 6, 0x222222); px(g, 175, 42, 4, 1, 0x222222);
  for (const wx of [196, 256]) {                                         // Fenster
    px(g, wx, 26, 52, 64, 0xf4f4f4); px(g, wx + 3, 29, 46, 58, 0x8fd3ff); px(g, wx + 3, 70, 46, 17, 0x7fc4ef);
    px(g, wx + 25, 29, 2, 58, 0xf4f4f4); px(g, wx + 3, 57, 46, 2, 0xf4f4f4);
    px(g, wx + 8, 36, 12, 4, 0xffffff); px(g, wx + 11, 33, 6, 3, 0xffffff); px(g, wx + 32, 45, 10, 3, 0xffffff);
    px(g, wx + 4, 78, 20, 9, 0x5bb04f); px(g, wx - 2, 90, 56, 3, 0xd9d0b8);
  }
  for (const dx of [20, 85, 150, 215, 280]) desk(g, dx);

  // ---- Schulflur (320-640) ----
  for (let i = 0; i < 7; i++) {                                         // Spinde
    const lx = 330 + i * 19;
    px(g, lx, 40, 18, 65, [0x3d6fb6, 0xc94a4a, 0x3d6fb6, 0xe0a23b, 0x3d6fb6, 0x4fa36b, 0x3d6fb6][i]);
    px(g, lx, 40, 18, 2, 0xffffff); px(g, lx + 17, 40, 1, 65, 0x22344f);
    for (let v = 0; v < 3; v++) px(g, lx + 4, 46 + v * 3, 10, 1, 0x22344f);
    px(g, lx + 13, 70, 2, 5, 0xd0d0d0);
  }
  px(g, 480, 32, 52, 40, 0x8a5a2b); px(g, 482, 34, 48, 36, 0xc9975b);   // Pinnwand
  const notes = [[486, 38, 0xffffff], [500, 37, 0xffe66d], [515, 40, 0xff9bd5], [489, 54, 0x9be7ff], [505, 52, 0xffffff], [517, 56, 0xb5f5a0]] as const;
  notes.forEach(([x, y, c]) => { px(g, x, y, 11, 12, c); px(g, x + 5, y, 1, 1, 0xd23b3b); });
  px(g, 545, 30, 26, 36, 0xd23b3b); write(g, 'ABI', 552, 36, 0xffffff); write(g, '26', 554, 46, 0xffcc33); px(g, 549, 58, 18, 2, 0xffffff); // Poster
  px(g, 585, 38, 40, 67, 0x7a4b2a); px(g, 588, 41, 34, 64, 0xa8703f);   // Tür
  px(g, 594, 47, 22, 18, 0xbfe6ff); px(g, 616, 75, 3, 2, 0xe0c060);
  px(g, 588, 24, 34, 9, 0x2a7a3a); write(g, 'EXIT', 592, 26, 0xffffff);
  for (const dx of [340, 440]) bench(g, dx);
  g.generateTexture('bg-school', 640 * P, 135 * P);
}

/** 640x135 Pixel: Turnhalle. */
function makeGym(g: G) {
  g.clear();
  px(g, 0, 0, 640, 135, 0xe6e6ec);
  px(g, 0, 0, 640, 31, 0x17171a); px(g, 0, 31, 640, 1, 0x8a8a8a);           // Dachträger
  for (let x = 0; x < 640; x += 16) { px(g, x, 25, 10, 2, 0x2c2c31); px(g, x + 6, 28, 8, 1, 0x2c2c31); }
  for (const wx of [20, 150, 330, 470]) {                                    // Fensterband
    px(g, wx, 36, 100, 28, 0x162744); px(g, wx + 2, 38, 96, 24, 0x4d86a8);
    for (let i = 0; i < 20; i++) { px(g, wx + 30 + i, 60 - i, 6, 1, 0x6fa3bf); px(g, wx + 62 + i, 60 - i, 3, 1, 0x6fa3bf); }
    px(g, wx + 24, 38, 1, 24, 0x162744); px(g, wx + 75, 38, 1, 24, 0x162744); px(g, wx + 25, 52, 50, 1, 0x162744);
  }
  px(g, 0, 82, 640, 53, 0x2f4f9e); px(g, 0, 82, 640, 1, 0x1f3572);          // Prallschutzwand
  for (let i = 0; i < 420; i++) px(g, (i * 37) % 640, 84 + (i * 53) % 50, 1, 1, i % 3 ? 0x4a6bc0 : 0x8aa3e0);
  px(g, 266, 60, 50, 17, 0x111111); px(g, 267, 61, 48, 15, 0x2a2a2a);       // Anzeigetafel
  write(g, '12', 271, 66, 0xff3b3b); write(g, '08', 303, 66, 0xff3b3b); px(g, 290, 67, 1, 1, 0xffcc33); px(g, 290, 70, 1, 1, 0xffcc33);
  px(g, 556, 54, 34, 24, 0x111111); px(g, 557, 55, 32, 22, 0xffffff);       // Basketballkorb
  px(g, 566, 62, 14, 10, 0x111111); px(g, 567, 63, 12, 8, 0xffffff);
  px(g, 568, 73, 10, 1, 0xe8742a); for (let i = 0; i < 4; i++) px(g, 569 + i * 2 + (i % 2), 74, 1, 4, 0xcfcfcf);
  for (const sx of [112, 440]) {                                            // Sprossenwände
    px(g, sx, 86, 2, 49, 0xa8703f); px(g, sx + 17, 86, 2, 49, 0xa8703f); px(g, sx + 34, 86, 2, 49, 0xa8703f);
    for (let y = 89; y < 134; y += 5) px(g, sx, y, 36, 1, 0xc98b4f);
  }
  px(g, 60, 92, 22, 43, 0x0e1530); px(g, 61, 93, 20, 42, 0x2a4488); px(g, 77, 112, 2, 1, 0xc0c0c0); // Tür
  px(g, 52, 100, 3, 3, 0xffffff); px(g, 53, 101, 1, 1, 0x2a4488);
  g.generateTexture('bg-gym', 640 * P, 135 * P);
}

/** 640x135 Pixel: Physik- und Chemieraum. */
function makeLab(g: G) {
  g.clear();
  px(g, 0, 0, 640, 135, 0xdfe9e4);
  px(g, 0, 0, 640, 24, 0xb8c4be); px(g, 0, 23, 640, 1, 0x8b9690);
  for (let x = 0; x < 640; x += 80) { px(g, x + 15, 24, 50, 2, 0xffffff); px(g, x + 15, 26, 50, 1, 0xcfe9ff); }
  px(g, 0, 105, 640, 30, 0x9fc4d6); px(g, 0, 105, 640, 1, 0x6f9db2); px(g, 0, 120, 640, 1, 0x86b3c8);
  for (let x = 0; x < 640; x += 10) px(g, x, 106, 1, 29, 0x86b3c8);
  // Periodensystem
  px(g, 18, 32, 84, 50, 0x333a44); px(g, 20, 34, 80, 46, 0xf4f4f4); write(g, 'PSE', 22, 36, 0x333a44);
  const cols = [0xff6b6b, 0xffb347, 0xffe066, 0x7bd389, 0x5bc0eb, 0xb58cf0];
  for (let r = 0; r < 6; r++) for (let c = 0; c < 18; c++) {
    if ((r === 0 && c > 0 && c < 17) || (r < 3 && r > 0 && c > 1 && c < 12)) continue;
    px(g, 23 + c * 4, 44 + r * 6, 3, 5, cols[c < 2 ? 0 : c < 12 ? 1 + (c % 2) : 3 + ((c + r) % 3)]);
  }
  // Tafel mit Formeln und Atom
  px(g, 116, 32, 108, 56, 0x4a3526); px(g, 119, 35, 102, 50, 0x23463a);
  write(g, 'F=MA', 126, 41, 0xf4f4f4); write(g, 'H2O', 126, 53, 0x9be7ff); write(g, 'E=MC2', 126, 65, 0xffe66d);
  for (let a = 0; a < 40; a++) {
    const t = a / 40 * Math.PI * 2;
    px(g, Math.round(190 + Math.cos(t) * 18), Math.round(60 + Math.sin(t) * 7), 1, 1, 0xdfe9df);
    px(g, Math.round(190 + Math.cos(t) * 7), Math.round(60 + Math.sin(t) * 18), 1, 1, 0xdfe9df);
  }
  px(g, 189, 59, 3, 3, 0xff6b6b); px(g, 207, 58, 2, 2, 0xffe066); px(g, 186, 43, 2, 2, 0xffe066);
  px(g, 116, 88, 108, 3, 0x8f5a2e);
  // Regal mit Kolben und Flaschen
  for (const sy of [60, 84]) { px(g, 242, sy, 88, 2, 0x8f5a2e); px(g, 246, sy + 2, 2, 4, 0x6b4426); px(g, 324, sy + 2, 2, 4, 0x6b4426); }
  const liquids = [0xff6b6b, 0x5bc0eb, 0x7bd389, 0xb58cf0, 0xffe066, 0xff9bd5];
  liquids.forEach((c, i) => {
    const x = 247 + i * 14;
    px(g, x + 2, 49, 2, 5, 0xeef8ff); px(g, x + 1, 54, 4, 1, 0xeef8ff); px(g, x, 55, 6, 5, 0xeef8ff); px(g, x + 1, 57, 4, 3, c);
    px(g, x + 1, 74, 4, 10, liquids[(i + 2) % 6]); px(g, x + 2, 72, 2, 2, 0x555b66); px(g, x + 1, 77, 4, 3, 0xf4f4f4);
  });
  // Fenster
  px(g, 344, 30, 62, 60, 0xf4f4f4); px(g, 347, 33, 56, 54, 0x8fd3ff); px(g, 347, 70, 56, 17, 0x7fc4ef);
  px(g, 374, 33, 2, 54, 0xf4f4f4); px(g, 347, 59, 56, 2, 0xf4f4f4); px(g, 353, 40, 12, 4, 0xffffff); px(g, 384, 47, 10, 3, 0xffffff);
  // Abzug
  px(g, 420, 34, 66, 71, 0x9aa3a8); px(g, 423, 37, 60, 40, 0xcfe6f2); px(g, 423, 37, 60, 2, 0x7d868b); px(g, 423, 77, 60, 3, 0x5f676b);
  px(g, 430, 84, 46, 18, 0x848d92); px(g, 434, 90, 3, 3, 0xd23b3b); px(g, 442, 90, 3, 3, 0x3d6fb6);
  px(g, 451, 64, 2, 5, 0xeef8ff); px(g, 449, 69, 6, 6, 0xeef8ff); px(g, 450, 71, 4, 4, 0x7bd389);
  // Skelett „Herr Knochen“
  const B = 0xf4f4f4;
  px(g, 510, 103, 17, 2, 0x555555); px(g, 518, 40, 1, 63, 0x555555); px(g, 514, 44, 9, 7, B); px(g, 516, 46, 2, 2, 0x222222); px(g, 520, 46, 2, 2, 0x222222);
  px(g, 516, 51, 5, 2, B); px(g, 518, 53, 1, 22, B); for (let i = 0; i < 5; i++) px(g, 514, 55 + i * 3, 9, 1, B);
  px(g, 512, 55, 1, 16, B); px(g, 524, 55, 1, 16, B); px(g, 515, 75, 7, 3, B); px(g, 515, 78, 1, 24, B); px(g, 521, 78, 1, 24, B);
  px(g, 513, 102, 3, 1, B); px(g, 521, 102, 3, 1, B);
  // Warnschild, Feuerlöscher
  for (let i = 0; i < 10; i++) px(g, 569 - i, 36 + i, i * 2 + 1, 1, 0xffd23f);
  px(g, 569, 39, 1, 4, 0x222222); px(g, 569, 44, 1, 1, 0x222222);
  px(g, 590, 84, 6, 18, 0xd23b3b); px(g, 591, 80, 4, 4, 0x333333); px(g, 596, 82, 4, 1, 0x333333); px(g, 591, 90, 4, 3, 0xf4f4f4);
  g.generateTexture('bg-lab', 640 * P, 135 * P);
}

function desk(g: G, x: number) {
  px(g, x + 6, 100, 18, 3, 0xb5763f); px(g, x + 7, 103, 2, 2, 0x555555); px(g, x + 21, 103, 2, 2, 0x555555); // Tisch
  px(g, x + 26, 97, 8, 2, 0x3d6fb6); px(g, x + 26, 99, 2, 6, 0x3d6fb6); px(g, x + 27, 101, 7, 2, 0x3d6fb6); // Stuhl
  px(g, x + 10, 98, 6, 2, 0xffffff);                                    // Heft
}
function bench(g: G, x: number) {
  px(g, x, 98, 40, 3, 0x8f5a2e); px(g, x + 2, 101, 2, 4, 0x555555); px(g, x + 36, 101, 2, 4, 0x555555);
}
