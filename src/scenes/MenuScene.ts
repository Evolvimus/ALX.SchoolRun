import Phaser from 'phaser';
import { button, FONT, menuBackground, portraitKey } from './ui';
import { save } from '../services/save';
import { getCharacter } from '../data/characters';
import { isTestMode } from '../services/backend';
import { sfx } from '../services/audio';
import { BESTIARY } from '../data/bestiary';

export class MenuScene extends Phaser.Scene {
  constructor() { super('Menu'); }
  create() {
    // Entwickler-Abkürzung: ?level=2 startet direkt ein Level
    const direct = new URLSearchParams(location.search).get('level');
    if (direct !== null && !this.registry.get('directDone')) {
      this.registry.set('directDone', true);
      this.scene.start('Game', { level: Number(direct) });
      return;
    }
    menuBackground(this);
    // Fallende Ginkgoblätter
    this.add.particles(0, 0, 'leaf', {
      x: { min: 0, max: 960 }, y: -20, lifespan: 9000, speedY: { min: 45, max: 90 }, speedX: { min: -30, max: 30 },
      rotate: { start: 0, end: 360 }, scale: { min: 0.45, max: 0.8 }, alpha: { min: 0.5, max: 0.95 }, frequency: 420,
    });

    this.add.image(112, 88, 'leaf-logo').setAngle(-12).setScale(0.72);
    this.add.text(520, 80, 'ALX SchoolRun', { fontFamily: FONT, fontSize: '40px', color: '#ffcc33', fontStyle: 'bold' })
      .setOrigin(0.5).setStroke('#000', 8);
    this.add.text(520, 132, 'Bring dem alten Ginkgo seine goldenen Blätter zurück!', { fontFamily: FONT, fontSize: '11px', color: '#fff' }).setOrigin(0.5);

    // Wer noch nie gespielt hat, startet direkt im Tutorial
    const tutorialDone = save.bestTimes['tutorial'] !== undefined;
    button(this, 480, 196, 'Spielen', () => this.scene.start(tutorialDone ? 'Levels' : 'Game', { level: 0 }), 320, 48);
    button(this, 480, 252, 'Charaktere', () => this.scene.start('Characters'), 320, 48);
    button(this, 480, 308, `Gegner-Lexikon  ${save.seen.length}/${BESTIARY.length}`, () => this.scene.start('Lexikon'), 320, 48);
    button(this, 480, 364, 'Code einlösen', () => this.scene.start('Redeem'), 320, 48);
    button(this, 480, 420, 'Lehrerzimmer-Shop', () => this.scene.start('Shop'), 320, 48);

    const c = getCharacter(save.selected);
    const img = this.add.image(800, 330, portraitKey(this, c));
    img.setScale(Math.min(140 / img.width, 180 / img.height));
    this.tweens.add({ targets: img, y: 324, duration: 900, yoyo: true, repeat: -1, ease: 'Sine.InOut' });
    this.add.text(800, 440, c.name, { fontFamily: FONT, fontSize: '12px', color: '#fff' }).setOrigin(0.5);
    this.add.text(20, 20, `${save.coins} Ginkgo-Taler`, { fontFamily: FONT, fontSize: '14px', color: '#ffd700' });
    this.add.text(940, 20, `${save.unlocked.length - 1}/20 Lehrer`, { fontFamily: FONT, fontSize: '12px', color: '#fff' }).setOrigin(1, 0);

    const sound = this.add.text(20, 512, '', { fontFamily: FONT, fontSize: '10px', color: '#c8c8d8' }).setInteractive({ useHandCursor: true });
    const label = () => sound.setText(save.muted ? 'TON: AUS' : 'TON: AN');
    label();
    sound.on('pointerup', () => { sfx.toggleMute(); label(); });
    if (isTestMode) this.add.text(480, 525, 'TESTMODUS (kein Server verbunden)', { fontFamily: FONT, fontSize: '9px', color: '#ff7777' }).setOrigin(0.5);
  }
}
