// Kleine Chiptune-Soundeffekte, komplett per WebAudio erzeugt (keine Dateien).
import { persist, save } from './save';

let ctx: AudioContext | null = null;
function ac(): AudioContext | null {
  if (!ctx) {
    try { ctx = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)(); }
    catch { return null; }
  }
  if (ctx.state === 'suspended') ctx.resume().catch(() => {});
  return ctx;
}

interface ToneOpts { type?: OscillatorType; vol?: number; slide?: number; delay?: number; }
function tone(freq: number, dur: number, o: ToneOpts = {}) {
  if (save.muted) return;
  const c = ac(); if (!c) return;
  const t0 = c.currentTime + (o.delay ?? 0);
  const osc = c.createOscillator(), gain = c.createGain();
  osc.type = o.type ?? 'square';
  osc.frequency.setValueAtTime(freq, t0);
  if (o.slide) osc.frequency.exponentialRampToValueAtTime(Math.max(30, freq * o.slide), t0 + dur);
  gain.gain.setValueAtTime(o.vol ?? 0.06, t0);
  gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  osc.connect(gain).connect(c.destination);
  osc.start(t0); osc.stop(t0 + dur + 0.02);
}

function noise(dur: number, vol = 0.05, delay = 0) {
  if (save.muted) return;
  const c = ac(); if (!c) return;
  const buf = c.createBuffer(1, Math.ceil(c.sampleRate * dur), c.sampleRate);
  const data = buf.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
  const src = c.createBufferSource(), gain = c.createGain();
  const t0 = c.currentTime + delay;
  src.buffer = buf;
  gain.gain.setValueAtTime(vol, t0);
  gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  src.connect(gain).connect(c.destination);
  src.start(t0);
}

const seq = (notes: number[], step: number, o: ToneOpts = {}) =>
  notes.forEach((f, i) => tone(f, step * 1.6, { type: 'triangle', vol: 0.08, ...o, delay: i * step }));

export const sfx = {
  jump: () => tone(330, 0.14, { slide: 1.9 }),
  airJump: () => tone(440, 0.14, { slide: 2.0 }),
  land: () => noise(0.05, 0.03),
  /** Blatt eingesammelt – je länger die Serie, desto höher der Ton. */
  leaf: (combo: number) => {
    const f = 660 * Math.pow(1.06, Math.min(combo, 14));
    tone(f, 0.07, { type: 'triangle', vol: 0.09 });
    tone(f * 1.5, 0.1, { type: 'triangle', vol: 0.07, delay: 0.05 });
  },
  swing: () => noise(0.07, 0.04),
  hit: () => { tone(180, 0.1, { slide: 0.5, vol: 0.09 }); noise(0.06, 0.06); },
  defeat: () => { tone(520, 0.08); tone(780, 0.12, { delay: 0.07 }); },
  hurt: () => tone(220, 0.3, { type: 'sawtooth', slide: 0.35, vol: 0.09 }),
  bounce: () => tone(200, 0.2, { slide: 3, type: 'triangle', vol: 0.1 }),
  checkpoint: () => seq([523, 659, 784, 1047], 0.08),
  rustle: () => { noise(0.12, 0.03); noise(0.12, 0.03, 0.18); },
  flame: () => noise(0.45, 0.035),
  blow: () => noise(0.6, 0.025),
  crunch: () => { noise(0.05, 0.05); tone(140, 0.05, { vol: 0.05 }); },
  zap: () => tone(90, 0.18, { type: 'sawtooth', slide: 2.5, vol: 0.05 }),
  win: () => seq([523, 659, 784, 659, 784, 1047], 0.11),
  over: () => seq([392, 330, 262, 196], 0.16, { type: 'sawtooth', vol: 0.06 }),
  click: () => tone(700, 0.04, { vol: 0.04 }),
  toggleMute: () => { save.muted = !save.muted; persist(); if (!save.muted) tone(700, 0.05); return save.muted; },
};
