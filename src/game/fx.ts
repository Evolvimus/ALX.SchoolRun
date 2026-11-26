import Phaser from 'phaser';
import { FONT } from '../scenes/ui';

type Emitter = Phaser.GameObjects.Particles.ParticleEmitter;

/** Partikel und schwebende Texte – das „Juice“ des Spiels. */
export class Fx {
  private dot: Emitter;
  private puff: Emitter;
  private leaf: Emitter;
  private color = 0xffffff;

  constructor(private scene: Phaser.Scene) {
    this.dot = scene.add.particles(0, 0, 'dot', {
      lifespan: { min: 220, max: 480 }, speed: { min: 60, max: 210 }, angle: { min: 0, max: 360 },
      scale: { start: 1.5, end: 0 }, gravityY: 600, tint: { onEmit: () => this.color }, emitting: false,
    }).setDepth(15);
    this.puff = scene.add.particles(0, 0, 'dot', {
      lifespan: { min: 250, max: 450 }, speedX: { min: -55, max: 55 }, speedY: { min: -45, max: -5 },
      scale: { start: 1.7, end: 0 }, alpha: { start: 0.7, end: 0 }, tint: 0xcfcfd6, emitting: false,
    }).setDepth(9);
    this.leaf = scene.add.particles(0, 0, 'leaf-s', {
      lifespan: { min: 500, max: 900 }, speed: { min: 70, max: 230 }, angle: { min: 200, max: 340 },
      rotate: { min: -180, max: 180 }, scale: { start: 1, end: 0.2 }, gravityY: 330, emitting: false,
    }).setDepth(15);
  }

  burst(x: number, y: number, color: number, n = 8) { this.color = color; this.dot.emitParticleAt(x, y, n); }
  dust(x: number, y: number, n = 4) { this.puff.emitParticleAt(x, y, n); }
  leaves(x: number, y: number, n = 6) { this.leaf.emitParticleAt(x, y, n); }

  text(x: number, y: number, str: string, color = '#ffe98a') {
    const t = this.scene.add.text(x, y, str, { fontFamily: FONT, fontSize: '12px', color }).setOrigin(0.5).setDepth(16).setStroke('#000', 4);
    this.scene.tweens.add({ targets: t, y: y - 38, alpha: 0, duration: 750, ease: 'Cubic.Out', onComplete: () => t.destroy() });
  }

  /** Windstreifen eines Laubbläsers. */
  wind(x: number, y: number, dir: number, len: number) {
    const w = this.scene.add.image(x, y, 'wind').setDepth(9).setAlpha(0.7);
    this.scene.tweens.add({ targets: w, x: x + dir * len, alpha: 0, duration: 520, onComplete: () => w.destroy() });
  }
}
