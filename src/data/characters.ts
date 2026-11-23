// Die 20 Lehrer-Charaktere. Namen, Farben und Fähigkeiten sind PLATZHALTER,
// bis das Abikomitee die echten Bilder und Infos liefert.
// Bild ablegen unter: public/characters/<id>.png (z. B. public/characters/lehrer01.png)

export type Rarity = 'gewoehnlich' | 'selten' | 'episch' | 'legendaer';
export type Ability = 'none' | 'doubleJump' | 'speed' | 'highJump' | 'glide' | 'smash';

export interface Character {
  id: string;
  name: string;
  subject: string;
  rarity: Rarity;
  ability: Ability;
  color: number; // Platzhalterfarbe, solange kein Bild da ist
  price: number; // Preis in Ginkgo-Talern, nach Ende der Kartenaktion
  starter?: boolean;
}

export const RARITY_LABEL: Record<Rarity, string> = {
  gewoehnlich: 'Gewöhnlich', selten: 'Selten', episch: 'Episch', legendaer: 'Legendär',
};
export const RARITY_COLOR: Record<Rarity, number> = {
  gewoehnlich: 0xb0b0b0, selten: 0x4aa3ff, episch: 0xb45cff, legendaer: 0xffb627,
};
export const ABILITY_LABEL: Record<Ability, string> = {
  none: 'Keine', doubleJump: 'Doppelsprung', speed: 'Sprinter', highJump: 'Supersprung',
  glide: 'Gleiten (Sprung halten)', smash: 'Kisten zerschlagen',
};
const PRICE: Record<Rarity, number> = { gewoehnlich: 150, selten: 300, episch: 600, legendaer: 1200 };

const rarities: Rarity[] = [
  'gewoehnlich','gewoehnlich','gewoehnlich','gewoehnlich','gewoehnlich','gewoehnlich','gewoehnlich','gewoehnlich',
  'selten','selten','selten','selten','selten','selten',
  'episch','episch','episch','episch',
  'legendaer','legendaer',
];
const abilities: Ability[] = ['doubleJump', 'speed', 'highJump', 'glide', 'smash'];
const colors = [0xe6194b,0x3cb44b,0xffe119,0x4363d8,0xf58231,0x911eb4,0x46f0f0,0xf032e6,0xbcf60c,0xfabebe,
  0x008080,0xe6beff,0x9a6324,0xfffac8,0x800000,0xaaffc3,0x808000,0xffd8b1,0x000075,0xffffff];

export const STARTER: Character = {
  id: 'schueler', name: 'Abiturient*in', subject: 'Abi 2026', rarity: 'gewoehnlich',
  ability: 'none', color: 0xffcc33, price: 0, starter: true,
};

export const TEACHERS: Character[] = rarities.map((rarity, i) => {
  const n = String(i + 1).padStart(2, '0');
  return {
    id: `lehrer${n}`,
    name: i === 0 ? 'Herr Hammer' : `Lehrer ${n}`,
    subject: i === 0 ? 'Werken' : 'Fach ?',
    rarity,
    ability: i === 0 ? 'smash' : abilities[i % abilities.length],
    color: colors[i],
    price: PRICE[rarity],
  };
});

export const ALL_CHARACTERS: Character[] = [STARTER, ...TEACHERS];
export const getCharacter = (id: string) => ALL_CHARACTERS.find(c => c.id === id) ?? STARTER;
