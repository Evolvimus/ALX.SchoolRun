// Gemeinsames Codeformat: ALX-XXXX-XXXX (8 Zeichen, letztes = Prüfzeichen).
// Ohne verwechselbare Zeichen (0/O, 1/I/L). Das Prüfzeichen fängt nur Tippfehler ab –
// ob ein Code echt und noch unbenutzt ist, entscheidet ausschließlich der Server.
export const ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

export function checkChar(body: string): string {
  let sum = 0;
  for (let i = 0; i < body.length; i++) sum += (ALPHABET.indexOf(body[i]) + 1) * (i + 3);
  return ALPHABET[sum % ALPHABET.length];
}

export function normalizeCode(input: string): string {
  const raw = input.toUpperCase().replace(/[^A-Z0-9]/g, '').replace(/^ALX/, '')
    .replace(/O/g, '0').replace(/[IL]/g, '1');
  return raw;
}

/** Gibt den formatierten Code zurück oder null bei Tippfehler. */
export function validateCode(input: string): string | null {
  const raw = normalizeCode(input);
  if (raw.length !== 8 || [...raw].some(c => !ALPHABET.includes(c))) return null;
  if (checkChar(raw.slice(0, 7)) !== raw[7]) return null;
  return `ALX-${raw.slice(0, 4)}-${raw.slice(4)}`;
}
