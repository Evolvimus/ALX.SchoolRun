// Die Lehrer-Charaktere. Bis auf Herrn Hammer sind Namen, Fächer und Fähigkeiten noch PLATZHALTER,
// bis das Abikomitee die echten Infos liefert.
//
// Seltenheiten: selten → super selten → episch → legendär → mythisch.
// „Mythisch“ ist keine eigene Person, sondern die Spezialversion eines Lehrers
// (gleiche Person, aber mit Extra-Fähigkeiten, goldener Waffe und Glitzer-Spur).

export type Rarity = 'selten' | 'superSelten' | 'episch' | 'legendaer' | 'mythisch';
export type Ability = 'none' | 'doubleJump' | 'speed' | 'highJump' | 'glide' | 'smash';

/** Aussehen der Pixel-Figur. Fehlt es, wird eine Standardfigur in der Platzhalterfarbe gezeichnet. */
export interface Look {
  hair: number; skin: number; shirt: number; vest: number; tie: number;
  belt: number; pants: number; shoes: number; glasses: number; stubble: number;
  /** Farbe der Brillengläser (Standard: durchsichtig). */
  lens?: number;
  /** Zopf am Hinterkopf. */
  ponytail?: boolean;
}

export interface Character {
  id: string;
  name: string;
  subject: string;
  rarity: Rarity;
  ability: Ability;
  /** Zusätzliche Fähigkeiten (nur mythische Versionen). */
  bonus?: Ability[];
  /** Waffe statt Lineal. */
  weapon?: 'ruler' | 'hammer' | 'goldHammer';
  /** Sprüche, die im Level als Sprechblase erscheinen. */
  quotes?: string[];
  /** Spruch beim Zerschlagen einer Kiste. */
  smashQuote?: string;
  look?: Look;
  /** Bei mythischen Versionen: ID der normalen Version. */
  variantOf?: string;
  color: number; // Platzhalterfarbe, solange es kein eigenes Aussehen gibt
  price: number; // Preis in Ginkgo-Talern im Shop; 0 = nur per Karte
  starter?: boolean;
}

export const RARITY_LABEL: Record<Rarity, string> = {
  selten: 'Selten', superSelten: 'Super selten', episch: 'Episch', legendaer: 'Legendär', mythisch: 'Mythisch',
};
export const RARITY_COLOR: Record<Rarity, number> = {
  selten: 0x4aa3ff, superSelten: 0x3ddc84, episch: 0xb45cff, legendaer: 0xffb627, mythisch: 0xff3d7f,
};
export const ABILITY_LABEL: Record<Ability, string> = {
  none: 'Keine', doubleJump: 'Doppelsprung', speed: 'Sprinter', highJump: 'Supersprung',
  glide: 'Gleiten (Sprung halten)', smash: 'Kisten zerschlagen',
};
// Mythische Versionen gibt es nur über Sammelkarten, nicht im Shop.
const PRICE: Record<Rarity, number> = { selten: 150, superSelten: 300, episch: 600, legendaer: 1200, mythisch: 0 };

export const hasAbility = (c: Character, a: Ability) => c.ability === a || !!c.bonus?.includes(a);
export const abilityText = (c: Character) => [c.ability, ...(c.bonus ?? [])].map(a => ABILITY_LABEL[a]).join(' + ');

// ---------------------------------------------------------------- Herr Hammer
const HAMMER_LOOK: Look = {
  hair: 0x4a3220, skin: 0xf0c4a0, shirt: 0x2f5f63, vest: 0x5a5a5e, tie: 0x6fa3a0,
  belt: 0x7a4a24, pants: 0x34476e, shoes: 0x5a3a22, glasses: 0x2e2a2a, stubble: 0xc99a78, ponytail: true,
};
const HAMMER_QUOTES = [
  'Ethik ist wie Religion,\nnur ohne Weihnachten.',
  'Ich hatte Deutsch\nLeistungskurs.',
  'Wer mag kein Nutella?',
  'Ich bin noch nicht satt\ngegessen am Leid.',
];
const HAMMER_SMASH = 'Das Feld wird auch nicht gefragt,\nob der Pflug drüber fährt!';

const HAMMER: Character = {
  id: 'lehrer01', name: 'Herr Hammer', subject: 'Chemie · Bio', rarity: 'legendaer',
  ability: 'smash', weapon: 'hammer', quotes: HAMMER_QUOTES, smashQuote: HAMMER_SMASH,
  look: HAMMER_LOOK, color: 0x5a5a5e, price: PRICE.legendaer,
};
const HAMMER_MYTHIC: Character = {
  ...HAMMER, id: 'lehrer01m', name: 'Admin Hammer', subject: 'Chemie · Bio · IT', rarity: 'mythisch',
  bonus: ['doubleJump'], weapon: 'goldHammer', variantOf: HAMMER.id,
  quotes: [...HAMMER_QUOTES, 'Hast du es schon mal mit\nAus- und Einschalten probiert?'],
  look: { ...HAMMER_LOOK, tie: 0xffc928, glasses: 0x12b8e0, lens: 0xb8f4ff }, price: PRICE.mythisch,
};

// ---------------------------------------------------------------- Platzhalter 02–20
const placeholderRarities: Rarity[] = [
  'selten', 'selten', 'selten', 'selten', 'selten', 'selten', 'selten',
  'superSelten', 'superSelten', 'superSelten', 'superSelten', 'superSelten', 'superSelten',
  'episch', 'episch', 'episch', 'episch',
  'legendaer', 'legendaer',
];
const abilities: Ability[] = ['doubleJump', 'speed', 'highJump', 'glide', 'smash'];
const colors = [0x3cb44b, 0xffe119, 0x4363d8, 0xf58231, 0x911eb4, 0x46f0f0, 0xf032e6, 0xbcf60c, 0xfabebe,
  0x008080, 0xe6beff, 0x9a6324, 0xfffac8, 0x800000, 0xaaffc3, 0x808000, 0xffd8b1, 0x000075, 0xffffff];

const PLACEHOLDERS: Character[] = placeholderRarities.map((rarity, i) => {
  const n = String(i + 2).padStart(2, '0');
  return {
    id: `lehrer${n}`, name: `Lehrer ${n}`, subject: 'Fach ?', rarity,
    ability: abilities[(i + 1) % abilities.length], color: colors[i], price: PRICE[rarity],
  };
});

export const STARTER: Character = {
  id: 'schueler', name: 'Abiturient*in', subject: 'Abi 2026', rarity: 'selten',
  ability: 'none', color: 0xffcc33, price: 0, starter: true,
};

/** Die normalen Lehrer:innen (eine Karte pro Person). */
export const BASE_TEACHERS: Character[] = [HAMMER, ...PLACEHOLDERS];
/** Mythische Spezialversionen. */
export const MYTHIC_TEACHERS: Character[] = [HAMMER_MYTHIC];
/** Alles, was per Karten-Code freigeschaltet werden kann. */
export const TEACHERS: Character[] = [...BASE_TEACHERS, ...MYTHIC_TEACHERS];

export const ALL_CHARACTERS: Character[] = [STARTER, ...TEACHERS];
export const getCharacter = (id: string) => ALL_CHARACTERS.find(c => c.id === id) ?? STARTER;
