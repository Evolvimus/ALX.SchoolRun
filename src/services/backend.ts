import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { TEACHERS } from '../data/characters';
import { checkChar, ALPHABET } from './codeFormat';
import { save } from './save';

export type RedeemResult =
  | { ok: true; characterId: string }
  | { ok: false; reason: 'invalid' | 'used' | 'network' };

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
const sb: SupabaseClient | null = url && key ? createClient(url, key, { auth: { persistSession: false } }) : null;

export const isTestMode = !sb;

/** Löst einen Code ein. Auf dem Server ist jeder Code genau EINMAL gültig. */
export async function redeemCode(code: string): Promise<RedeemResult> {
  if (!sb) return mockRedeem(code);
  const { data, error } = await sb.rpc('redeem_code', { p_code: code, p_player: save.playerId });
  if (error) {
    if (error.message.includes('CODE_USED')) return { ok: false, reason: 'used' };
    if (error.message.includes('CODE_INVALID')) return { ok: false, reason: 'invalid' };
    return { ok: false, reason: 'network' };
  }
  return { ok: true, characterId: data as string };
}

/** Stellt freigeschaltete Charaktere vom Server wieder her. */
export async function fetchUnlocks(): Promise<string[]> {
  if (!sb) return [];
  const { data } = await sb.rpc('my_unlocks', { p_player: save.playerId });
  return (data as string[] | null) ?? [];
}

/** Ist der Shop (Freischalten mit Spielwährung) schon geöffnet? Wird zentral vom Abikomitee gesetzt. */
export async function isShopOpen(): Promise<boolean> {
  if (!sb) return true; // im Testmodus immer offen
  const { data } = await sb.rpc('shop_open');
  return data === true;
}

// ---- Testmodus ohne Server: jeder formal gültige Code klappt einmal pro Gerät ----
/** Feste Testcodes, die im Testmodus immer denselben Lehrer freischalten. Auf dem Server gibt es sie nicht. */
export const TEST_CODES: Record<string, string> = { 'ALX-HAMM-ER2N': 'lehrer01' };

function mockRedeem(code: string): RedeemResult {
  if (TEST_CODES[code]) return { ok: true, characterId: TEST_CODES[code] };
  const used: string[] = JSON.parse(localStorage.getItem('alx-mock-used') ?? '[]');
  if (used.includes(code)) return { ok: false, reason: 'used' };
  used.push(code);
  localStorage.setItem('alx-mock-used', JSON.stringify(used));
  const raw = code.replace(/[^A-Z0-9]/g, '').slice(3);
  const idx = ALPHABET.indexOf(checkChar(raw)) % TEACHERS.length;
  return { ok: true, characterId: TEACHERS[idx].id };
}
