// Level als Textkarte (1 Zeichen = 1 Kachel à 45 px, 12 Zeilen; Boden ab Zeile 9, man steht in Zeile 8).
//
// Gelände:  # Boden   = Brett   R Bücherregal   L Labortisch   K Turnkasten   B Karton   M Matte (federt)   ^ Reißzwecken
// Ginkgo:   c Blatt   S Setzling (Checkpoint)   F großer Ginkgo (Ziel)   C großes Blatt mit Raupe
// Gegner:   m Staubmaus   e Papierflieger-Schwarm   w Wurmloch (benachbarte Löcher = ein Bücherwurm)
//           o Basketball  < > Laubbläser (bläst nach links/rechts)   N Magnet   f Bunsenbrenner
// Sonst:    P Start   T Übungsscheibe   D Tür (öffnet sich, wenn eine Tutorial-Aufgabe erledigt ist)
//
// Alles, was „steht“ (S F C f < > w), kommt in die Zelle direkt über seiner Standfläche.
/**
 * Eine Tutorial-Aufgabe. Sie erscheint, sobald man Spalte `at` erreicht, und ist erledigt, wenn `done` erfüllt ist.
 * Platzhalter im Text: {LAUFEN} {SPRINGEN} {HIEB} werden je nach Gerät durch Tasten oder Buttons ersetzt.
 */
export interface TutorialStep {
  at: number;
  text: string;
  done:
    | { type: 'col'; col: number }          // Spalte erreicht
    | { type: 'leaves'; count: number }     // so viele Blätter gesammelt
    | { type: 'checkpoint' }                // Setzling berührt
    | { type: 'defeat'; kind: string }      // Gegner dieser Art besiegt ('' = Übungsscheibe)
    | { type: 'timer'; ms: number }         // nur lesen
    | { type: 'goal' };                     // Ziel erreicht
  /** Öffnet nach dem Erledigen die nächste Tür */
  opensDoor?: boolean;
}

export interface Level {
  id: string;
  name: string;
  bg: string;
  map: string[];
  hints: [col: number, row: number, text: string][];
  tutorial?: TutorialStep[];
}

type Item = [string, number, number];

/** Baut eine Karte aus Lücken im Boden und einzelnen Objekten. */
function build(width: number, gaps: [number, number][], items: Item[]): string[] {
  const rows: string[][] = Array.from({ length: 12 }, (_, r) => Array.from({ length: width }, (_, c) =>
    r >= 9 && !gaps.some(([a, b]) => c >= a && c <= b) ? '#' : ' '));
  for (const [ch, col, row] of items) {
    if (rows[row][col] !== ' ') throw new Error(`Level-Fehler: Zelle ${col},${row} ist doppelt belegt (${rows[row][col]} und ${ch})`);
    rows[row][col] = ch;
  }
  return rows.map(r => r.join(''));
}
const line = (ch: string, from: number, to: number, row: number): Item[] =>
  Array.from({ length: to - from + 1 }, (_, i) => [ch, from + i, row]);
const at = (ch: string, ...cells: [number, number][]): Item[] => cells.map(([c, r]) => [ch, c, r]);

export const LEVELS: Level[] = [{
  id: 'tutorial',
  name: 'Erster Schultag',
  bg: 'bg-school',
  hints: [],
  tutorial: [
    { at: 0, text: 'Willkommen am ALX!\nLaufe mit {LAUFEN} nach rechts.', done: { type: 'col', col: 6 } },
    { at: 5, text: 'Spring mit {SPRINGEN} über die Lücke.', done: { type: 'col', col: 12 } },
    { at: 12, text: 'Halte {SPRINGEN} gedrückt:\nJe länger, desto höher springst du.', done: { type: 'col', col: 18 } },
    { at: 18, text: 'Sammle die goldenen Ginkgoblätter!', done: { type: 'leaves', count: 9 } },
    { at: 27, text: 'Ein Setzling! Lauf hindurch:\nNach einem Sturz geht es hier weiter.', done: { type: 'checkpoint' } },
    { at: 30, text: 'Schlag die Übungsscheibe mit dem Lineal: {HIEB}', done: { type: 'defeat', kind: '' }, opensDoor: true },
    { at: 36, text: 'Eine Staubmaus!\nSpring drauf oder schlag mit {HIEB} zu.', done: { type: 'defeat', kind: 'mouse' }, opensDoor: true },
    { at: 46, text: 'Jeden neuen Gegner findest du\nim Gegner-Lexikon im Menü.', done: { type: 'timer', ms: 3500 } },
    { at: 49, text: 'Blaue Turnmatten federn dich hoch!', done: { type: 'col', col: 58 } },
    { at: 58, text: 'Bring deine Blätter zum großen Ginkgo!', done: { type: 'goal' } },
  ],
  map: build(68, [[9, 10]], [
    ['P', 2, 8], ['c', 9, 6], ['c', 10, 6],
    ...at('R', [16, 8], [16, 7], [17, 8], [17, 7]),
    ...at('c', [20, 8], [21, 8], [22, 8], [23, 7], [24, 6], [25, 7], [26, 8]),
    ['S', 29, 8], ['T', 33, 8], ['D', 35, 8],
    ['m', 41, 8], ['D', 46, 8],
    ['M', 52, 8], ...line('=', 54, 57, 4), ...line('c', 54, 57, 3),
    ['F', 63, 8],
  ]),
}, {
  id: 'klassenzimmer',
  name: 'Klassenzimmer',
  bg: 'bg-school',
  hints: [
    [3, 5, 'LAUFEN: PFEILTASTEN\nSPRINGEN: LEERTASTE'],
    [29, 5, 'X: LINEAL-HIEB'],
    [72, 4, 'ES RASCHELT ...'],
  ],
  map: build(126, [[24, 26], [52, 54], [97, 99]], [
    ['P', 2, 8], ...line('c', 6, 9, 8),
    // Regal-Treppe
    ...at('R', [12, 8], [13, 8], [13, 7], [14, 8], [14, 7]), ...at('c', [12, 7], [13, 6], [14, 6]),
    ...line('c', 18, 20, 8), ...line('c', 24, 26, 6),
    // erste Staubmaus
    ['m', 34, 8], ...line('c', 37, 39, 8),
    ['S', 42, 8],
    ...line('=', 44, 47, 6), ...at('c', [45, 5], [46, 5]),
    ...line('=', 49, 51, 4), ...line('c', 49, 51, 3), ['c', 53, 6],
    // Reißzwecken, Karton, Papierflieger
    ...at('c', [57, 8], [58, 8]), ...at('^', [59, 8], [60, 8]), ...at('c', [59, 6], [60, 6]),
    ['B', 66, 8], ['c', 66, 7], ['e', 78, 6],
    ['S', 70, 8],
    // Bücherwurm im Regal
    ...line('R', 77, 81, 8), ...at('w', [78, 7], [80, 7], [84, 8]), ...at('c', [77, 7], [79, 7], [81, 7]),
    ...line('R', 87, 89, 8), ...line('R', 87, 89, 7), ['C', 88, 6],
    ...at('c', [91, 8], [92, 8]), ['m', 94, 8], ['c', 98, 6],
    ['S', 102, 8],
    // Finale
    ...at('R', [106, 8], [107, 8], [107, 7]), ...line('=', 109, 112, 5), ...line('c', 109, 112, 4),
    ['m', 111, 8], ...at('^', [115, 8], [116, 8]), ...at('c', [115, 6], [116, 6]), ['e', 117, 6],
    ['F', 121, 8],
  ]),
}, {
  id: 'turnhalle',
  name: 'Turnhalle',
  bg: 'bg-gym',
  hints: [
    [14, 4, 'VON OBEN FEDERT DER BALL'],
    [41, 4, 'LAUBBLÄSER: PAUSE ABWARTEN,\nDANN ZWEI HIEBE'],
  ],
  map: build(134, [[28, 31], [60, 62], [90, 94]], [
    ['P', 2, 8], ...line('c', 5, 8, 8),
    ...at('K', [11, 8], [12, 8], [12, 7]), ...at('c', [11, 7], [12, 6]),
    ['o', 17, 5], ...line('c', 16, 18, 8), ['m', 22, 8],
    // Matte über die erste Lücke
    ['M', 26, 8], ...at('c', [28, 3], [29, 2], [30, 2], [31, 3]),
    ['S', 36, 8], ...at('c', [39, 8], [40, 8]),
    // Laubbläser
    ['<', 50, 8], ...line('c', 45, 48, 8),
    ...at('K', [54, 8], [55, 8], [55, 7], [56, 8], [56, 7], [56, 6]), ...at('c', [54, 7], [55, 6], [56, 5]), ['c', 61, 6],
    ['o', 66, 5], ['o', 70, 4], ...at('c', [66, 8], [68, 8], [70, 8]),
    ['S', 74, 8],
    // Raupe hoch oben
    ['M', 77, 8], ...line('=', 79, 81, 5), ['C', 80, 4], ['m', 84, 8],
    ['M', 88, 8], ...line('=', 91, 93, 5), ...line('c', 91, 93, 4),
    // Rückenwind in die Reißzwecken
    ['>', 98, 8], ...line('c', 101, 103, 8), ...at('^', [105, 8], [106, 8]), ...at('c', [105, 6], [106, 6]),
    ['S', 109, 8],
    ...at('K', [112, 8], [112, 7]), ['o', 116, 4], ...at('c', [114, 8], [116, 8], [118, 8]), ['m', 121, 8],
    ['F', 128, 8],
  ]),
}, {
  id: 'physikraum',
  name: 'Physikraum',
  bg: 'bg-lab',
  hints: [
    [11, 4, 'BRENNER: AUF DIE PAUSE WARTEN'],
    [17, 6, 'MAGNET: BEI BLAU SPRINGEN'],
  ],
  map: build(140, [[22, 26], [60, 64]], [
    ['P', 2, 8], ...line('c', 5, 7, 8),
    ...at('L', [10, 8], [11, 8]), ...at('c', [10, 7], [11, 7]), ['f', 15, 8],
    // Magnet über der Lücke
    ['N', 24, 3], ...line('c', 23, 25, 5),
    ['S', 30, 8],
    ['f', 35, 8], ['c', 37, 8], ['f', 39, 8],
    ...line('L', 44, 47, 8), ...at('L', [46, 7], [47, 7]), ['f', 45, 7], ...at('c', [44, 7], [46, 6], [47, 6]),
    ...at('c', [50, 8], [51, 8]), ['m', 54, 8],
    ['N', 62, 3], ...line('c', 61, 63, 5),
    ['S', 68, 8],
    // Bücherwurm im Boden
    ...at('w', [73, 8], [77, 8], [81, 8]), ...at('c', [72, 8], [75, 8], [79, 8], [83, 8]),
    ...line('L', 86, 88, 8), ...line('L', 86, 88, 7), ['C', 87, 6],
    ['f', 92, 8], ['m', 96, 8],
    // Magnet über Reißzwecken
    ...line('^', 100, 103, 8), ['N', 102, 3], ...at('c', [101, 5], [102, 5]),
    ['S', 108, 8],
    // Brenner-Parcours
    ['f', 113, 8], ['c', 114, 8], ['f', 116, 8], ['c', 117, 8], ['f', 119, 8], ['c', 121, 8],
    ...at('L', [125, 8], [126, 8]), ...at('c', [125, 7], [126, 7]),
    ['F', 133, 8],
  ]),
}];

/** Anzeige-Name: „Tutorial“ oder die Levelnummer. */
export const levelLabel = (i: number) => (LEVELS[i]?.tutorial ? 'Tutorial' : String(i));

/** Wie viele Blätter es im Level insgesamt zu holen gibt. */
export function countLeaves(level: Level): number {
  return level.map.join('').split('').reduce((n, ch) => n + (ch === 'c' ? 1 : ch === 'C' ? 5 : 0), 0);
}
