// Einfacher Testbot (Aufruf mit ?bot=1): läuft nach rechts, springt über Lücken und Hindernisse,
// schlägt nach Gegnern und wartet bei Brennern und Magneten. Er prüft, ob ein Level lösbar ist.
import type { GameScene } from '../scenes/GameScene';
import { Controls } from './Player';
import { Ball, Bookworm, Burner, Magnet, Plane } from './enemies';

let holdUntil = 0;
let stuckX = 0;
let stuckSince = 0;

export function botControls(s: GameScene, time: number): Controls {
  const p = s.player, b = p.body;
  const c: Controls = { left: false, right: true, jump: false, attack: false };
  const ground = p.onGround;
  let wantJump = false;

  for (const e of s.enemies) {
    if (!e.alive) continue;
    if (e instanceof Burner) {
      const dx = e.x - p.x;
      if (dx > 0 && dx < 105 && e.safeFor(time) < 650) c.right = false;
      continue;
    }
    if (e instanceof Magnet) {
      const dx = e.x - p.x;
      if (ground && dx > 60 && dx < 300 && !(e.mode(time) > 0 && e.remaining(time) > 1500)) c.right = false;
      continue;
    }
    if (e instanceof Bookworm) {
      const h = e.active;
      if (h && h.x - p.x > 30 && h.x - p.x < 95 && !e.hitbox()) c.right = false; // vor dem raschelnden Loch warten
    }
    const hb = e.hitbox();
    if (!hb) continue;
    const dx = hb.centerX - p.x, dy = hb.centerY - p.y;
    if (e.hittable && dx > -20 && dx < (e instanceof Plane ? 135 : 88) && Math.abs(dy) < 62) c.attack = Math.floor(time / 70) % 2 === 0;
    if (e instanceof Ball && ground && dx > 20 && dx < 125 && hb.bottom > b.y - 70) c.right = false; // warten, bis der Ball oben ist
  }

  if (ground) {
    const feet = b.bottom - 6;
    if (s.solidAt(b.right + 14, feet) || s.crateAt(b.right + 14, feet)) wantJump = true;      // Wand
    if (!s.solidAt(b.center.x + 10, b.bottom + 10)) wantJump = true;                          // Abgrund
    if (s.spikes.some(r => r.x - b.right < 34 && r.right > b.x && Math.abs(r.bottom - b.bottom) < 40)) wantJump = true;
    if (Math.abs(p.x - stuckX) > 8) { stuckX = p.x; stuckSince = time; }
    else if (c.right && time - stuckSince > 2500) { wantJump = true; c.attack = true; stuckSince = time; }
  }
  if (!c.right) { stuckSince = time; wantJump = false; }

  if (wantJump && time > holdUntil + 60) holdUntil = time + 420;
  c.jump = time < holdUntil;
  return c;
}
