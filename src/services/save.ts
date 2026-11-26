// Lokaler Spielstand (funktioniert im Browser und in der Capacitor-App).
export interface SaveData {
  playerId: string;
  unlocked: string[];
  selected: string;
  coins: number;
  bestTimes: Record<string, number>;
  bestLeaves: Record<string, number>;
  progress: number; // höchstes freigeschaltetes Level (Index)
  muted: boolean;
  /** Gegner, die man schon gesehen hat (Gegner-Lexikon) */
  seen: string[];
  /** Wie oft welcher Gegner besiegt wurde */
  defeated: Record<string, number>;
}
const KEY = 'alx-schoolrun-save-v1';

function uuid(): string {
  return crypto.randomUUID ? crypto.randomUUID()
    : 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
        const r = (Math.random() * 16) | 0; return (c === 'x' ? r : (r & 3) | 8).toString(16);
      });
}

function load(): SaveData {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) return { ...fresh(), ...JSON.parse(raw) };
  } catch { /* ignorieren */ }
  return fresh();
}
function fresh(): SaveData {
  return { playerId: uuid(), unlocked: ['schueler'], selected: 'schueler', coins: 0, bestTimes: {}, bestLeaves: {}, progress: 1, muted: false, seen: [], defeated: {} };
}

export const save: SaveData = load();
export function persist() {
  try { localStorage.setItem(KEY, JSON.stringify(save)); } catch { /* ignorieren */ }
}
export function unlock(id: string) {
  if (!save.unlocked.includes(id)) save.unlocked.push(id);
  persist();
}
persist();
