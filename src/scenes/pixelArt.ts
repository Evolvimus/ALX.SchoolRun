// Pixel-Art-Grafiken, prozedural gezeichnet (1 Pixel = 3x3 Bildschirmpixel).
import Phaser from 'phaser';
import { ALL_CHARACTERS } from '../data/characters';

export const P = 3;
type G = Phaser.GameObjects.Graphics;

const px = (g: G, x: number, y: number, w: number, h: number, c: number) => { g.fillStyle(c).fillRect(x * P, y * P, w * P, h * P); };

function sprite(g: G, rows: string[], pal: Record<string, number>, ox = 0, oy = 0) {
  rows.forEach((r, y) => [...r].forEach((ch, x) => { if (pal[ch] !== undefined) px(g, ox + x, oy + y, 1, 1, pal[ch]); }));
}

// Mini-Pixelschrift (3x5) für Tafel und Poster
const FONT: Record<string, string[]> = {
  A: ['.#.', '#.#', '###', '#.#', '#.#'], B: ['##.', '#.#', '##.', '#.#', '##.'], I: ['###', '.#.', '.#.', '.#.', '###'],
  '2': ['##.', '..#', '.#.', '#..', '###'], '0': ['###', '#.#', '#.#', '#.#', '###'], '6': ['###', '#..', '###', '#.#', '###'],
  E: ['###', '#..', '##.', '#..', '###'], M: ['#.#', '###', '###', '#.#', '#.#'], C: ['###', '#..', '#..', '#..', '###'],
  '=': ['...', '###', '...', '###', '...'], X: ['#.#', '#.#', '.#.', '#.#', '#.#'], '+': ['...', '.#.', '###', '.#.', '...'],
  T: ['###', '.#.', '.#.', '.#.', '.#.'],
  L: ['#..', '#..', '#..', '#..', '###'], '1': ['.#.', '##.', '.#.', '.#.', '###'], ' ': ['...', '...', '...', '...', '...'],
};
function write(g: G, text: string, x: number, y: number, c: number) {
  [...text].forEach((ch, i) => sprite(g, FONT[ch] ?? FONT[' '], { '#': c }, x + i * 4, y));
}

const CHAR = [
  '...HHHHHH...', '..HHHHHHHH..', '.HHHHHHHHHH.', '.HHSSSSSSHH.', '.HSSSSSSSSH.', '..SEESSEES..',
  '..SSSSSSSS..', '..SSSMMSSS..', '...SSSSSS...', '..BBBDDBBB..', '.BBBBDDBBBB.', 'SBBBBBBBBBBS',
  'SSBBBBBBBBSS', '.SBBBBBBBBS.', '..BBBBBBBB..', '..PPPPPPPP..', '..PPP..PPP..', '..PPP..PPP..',
  '.KKKK..KKKK.', '.KKKK..KKKK.',
];
const HAIR = [0x3b2414, 0x8a5a2b, 0xd9b44a, 0x1a1a1a, 0xa0a0a0, 0xb5452b];

function darken(c: number, f = 0.7) {
  const r = (c >> 16) & 255, gg = (c >> 8) & 255, b = c & 255;
  return (Math.floor(r * f) << 16) | (Math.floor(gg * f) << 8) | Math.floor(b * f);
}

export function makePixelTextures(scene: Phaser.Scene) {
  const g = scene.add.graphics();
  const gen = (key: string, w: number, h: number, draw: () => void) => { g.clear(); draw(); g.generateTexture(key, w * P, h * P); };

  ALL_CHARACTERS.forEach((c, i) => gen(`char-${c.id}`, 12, 20, () => sprite(g, CHAR, {
    H: HAIR[i % HAIR.length], S: 0xf2c49b, E: 0x1a1a2e, M: 0xb5524a, B: c.color, D: darken(c.color), P: 0x2e3a5c, K: 0x222222,
  })));

  // Boden: helle Dielenkante oben, darunter dunkler Untergrund
  const dark = (top: boolean) => {
    px(g, 0, 0, 15, 15, 0x26262b);
    for (let i = 0; i < 14; i++) px(g, (i * 7 + (top ? 3 : 0)) % 15, (i * 11 + 4) % 15, 2, 1, i % 2 ? 0x34343b : 0x1b1b1f);
    if (top) { px(g, 0, 0, 15, 2, 0xd9652b); px(g, 0, 2, 15, 1, 0x8a3a14); px(g, 0, 0, 15, 1, 0xf08a4b); }
  };
  gen('ground', 15, 15, () => dark(true));
  gen('under', 15, 15, () => dark(false));
  // Turnkasten
  gen('box', 15, 15, () => {
    px(g, 0, 0, 15, 15, 0xd9a05b); px(g, 0, 0, 15, 2, 0xd9652b);
    for (const y of [5, 9, 13]) px(g, 0, y, 15, 1, 0x9a6a33);
    px(g, 0, 2, 1, 13, 0xb5803f); px(g, 14, 2, 1, 13, 0x9a6a33);
  });
  // Blaue Turnmatte (federt!)
  gen('mat', 15, 5, () => { px(g, 0, 0, 15, 5, 0x2d6fd6); px(g, 0, 0, 15, 1, 0x5a97f0); px(g, 0, 4, 15, 1, 0x1b4a99); px(g, 0, 0, 1, 5, 0x1b4a99); px(g, 14, 0, 1, 5, 0x1b4a99); });
  // Basketball
  gen('ball', 8, 8, () => sprite(g, ['..oooo..', '.ookooo.', 'oookoooo', 'kkkkkkkk', 'oookoooo', 'oookoooo', '.ookooo.', '..oooo..'], { o: 0xe8742a, k: 0x5a2a0c }));
  // Leben
  gen('heart', 7, 6, () => sprite(g, ['.##.##.', '#rw#rr#', '#rrrrr#', '.#rrr#.', '..#r#..', '...#...'], { '#': 0x5a0d0d, r: 0xe23b3b, w: 0xffb3b3 }));
  // Regalbrett / Pult als Plattform
  gen('platform', 15, 6, () => {
    px(g, 0, 0, 15, 6, 0x8f5a2e); px(g, 0, 0, 15, 2, 0xd69a5c); px(g, 0, 5, 15, 1, 0x4a2c17); px(g, 1, 3, 2, 1, 0x6b4426);
  });
  // Umzugskarton mit ABI-Aufdruck
  gen('crate', 15, 15, () => {
    px(g, 0, 0, 15, 15, 0xb8834c); px(g, 0, 0, 15, 1, 0xd9a86c); px(g, 0, 14, 15, 1, 0x7a5228); px(g, 14, 0, 1, 15, 0x7a5228);
    px(g, 6, 0, 3, 15, 0xd9c7a0); write(g, 'ABI', 2, 8, 0x8a2b2b);
  });
  // Münze (ALX-Taler)
  gen('coin', 8, 8, () => sprite(g, ['..####..', '.#yyyy#.', '#yywyyy#', '#ywyyyy#', '#yyyyyy#', '#yyyyyy#', '.#yyyy#.', '..####..'],
    { '#': 0xb07a00, y: 0xffd23f, w: 0xfff3b0 }));
  // Reißzwecken
  gen('spikes', 15, 15, () => {
    for (let i = 0; i < 3; i++) { const x = i * 5; px(g, x + 2, 9, 1, 5, 0xd8d8d8); px(g, x, 12, 5, 2, 0xd23b3b); px(g, x + 1, 11, 3, 1, 0xff6b6b); }
  });
  // Papierflieger
  gen('plane', 14, 7, () => sprite(g, ['#.............', '###...........', '#####.........', '##############', '.#########....', '..######......', '...##.........'],
    { '#': 0xf4f4f4 }));
  // Ziel: Fahne mit Abi-Hut
  gen('flag', 20, 45, () => {
    px(g, 0, 0, 2, 45, 0x555555); px(g, 2, 2, 16, 11, 0xffcc33); px(g, 2, 12, 16, 1, 0xb8901f);
    px(g, 6, 5, 8, 2, 0x1a1a2e); px(g, 8, 7, 4, 3, 0x1a1a2e); px(g, 13, 7, 1, 3, 0xd23b3b);
  });
  gen('touch', 30, 30, () => { g.fillStyle(0xffffff, 0.25).fillCircle(45, 45, 45); });
  makeBackground(g);
  makeGym(g);
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

function desk(g: G, x: number) {
  px(g, x + 6, 100, 18, 3, 0xb5763f); px(g, x + 7, 103, 2, 2, 0x555555); px(g, x + 21, 103, 2, 2, 0x555555); // Tisch
  px(g, x + 26, 97, 8, 2, 0x3d6fb6); px(g, x + 26, 99, 2, 6, 0x3d6fb6); px(g, x + 27, 101, 7, 2, 0x3d6fb6); // Stuhl
  px(g, x + 10, 98, 6, 2, 0xffffff);                                    // Heft
}
function bench(g: G, x: number) {
  px(g, x, 98, 40, 3, 0x8f5a2e); px(g, x + 2, 101, 2, 4, 0x555555); px(g, x + 36, 101, 2, 4, 0x555555);
}
