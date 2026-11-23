// Level als Textkarte (1 Zeichen = 1 Kachel à 45 px, 12 Zeilen; Boden ab Zeile 9).
// #=Boden  ==Plattform  c=Münze  B=Karton  K=Turnkasten  M=Matte (federt)  ^=Reißzwecken
// e=Papierflieger  o=hüpfender Ball  P=Start  F=Ziel
export interface Level { id: string; name: string; bg: string; map: string[]; }

/** Baut eine Karte aus Lücken im Boden und einzelnen Objekten – leichter zu pflegen als reiner Text. */
function build(width: number, gaps: [number, number][], items: [string, number, number][]): string[] {
  const rows: string[][] = Array.from({ length: 12 }, (_, r) => Array.from({ length: width }, (_, c) =>
    r >= 9 && !gaps.some(([a, b]) => c >= a && c <= b) ? '#' : ' '));
  for (const [ch, col, row] of items) rows[row][col] = ch;
  return rows.map(r => r.join(''));
}
const line = (ch: string, from: number, to: number, row: number): [string, number, number][] =>
  Array.from({ length: to - from + 1 }, (_, i) => [ch, from + i, row]);

export const LEVELS: Level[] = [{
  id: 'schulhof',
  name: 'Level 1 – Klassenzimmer',
  bg: 'bg-school',
  map: [
    '                                                                                              ',
    '                                                                                              ',
    '                                            ccc                                               ',
    '                       ccc                 =====              c c c                           ',
    '                      =====                                  =======          ccc             ',
    '            ccc                     e                                        =====         F  ',
    '           =====            cc               cc        e                                      ',
    '  P                  c c          =====     ====                    cc   B             cc     ',
    '               B    =====                          B         cc     BB   BB   c c    ====     ',
    '########    #####  ######  ^^  ######  #####  ##########  ######  #######  #######  ##########',
    '########    #####  ######  ##  ######  #####  ##########  ######  #######  #######  ##########',
    '########    #####  ######  ##  ######  #####  ##########  ######  #######  #######  ##########',
  ],
}, {
  id: 'turnhalle',
  name: 'Level 2 – Turnhalle',
  bg: 'bg-gym',
  map: build(96, [[30, 32], [58, 60]], [
    ['P', 2, 8], ...line('c', 6, 8, 7),
    ['K', 12, 8], ['K', 13, 8], ['K', 13, 7], ['c', 13, 5], ['c', 12, 6],
    ['o', 18, 5],
    ['M', 22, 8], ['c', 22, 4], ['c', 22, 3], ...line('=', 24, 27, 4), ['c', 25, 3], ['c', 26, 3],
    ['c', 31, 5], ['^', 35, 8], ['^', 36, 8],
    ['K', 40, 8], ['K', 41, 8], ['K', 41, 7], ['K', 42, 8], ['K', 42, 7], ['K', 42, 6], ['c', 42, 4], ['c', 44, 8], ['c', 45, 8],
    ['o', 48, 4], ['B', 52, 8],
    ['M', 55, 8], ...line('=', 57, 61, 5), ...line('c', 58, 60, 4),
    ['e', 68, 6],
    ['K', 70, 8], ['K', 70, 7], ['M', 72, 8], ...line('=', 74, 77, 3), ...line('c', 74, 77, 2),
    ['o', 80, 5], ['^', 83, 8], ['K', 86, 8], ['c', 86, 6],
    ['F', 91, 5],
  ]),
}];
