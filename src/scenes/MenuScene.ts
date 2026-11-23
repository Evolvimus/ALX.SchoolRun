import Phaser from 'phaser';
import { button, FONT, portraitKey } from './ui';
import { save } from '../services/save';
import { getCharacter } from '../data/characters';
import { isTestMode } from '../services/backend';

export class MenuScene extends Phaser.Scene {
  constructor() { super('Menu'); }
  create() {
    this.add.text(480, 80, 'ALX SchoolRun', { fontFamily: FONT, fontSize: '64px', color: '#ffcc33', fontStyle: 'bold' })
      .setOrigin(0.5).setStroke('#000', 8);
    this.add.text(480, 135, 'Das Jump & Run des Abikomitees', { fontFamily: FONT, fontSize: '22px', color: '#fff' }).setOrigin(0.5);

    button(this, 480, 220, '▶ Spielen', () => this.scene.start('Game'));
    button(this, 480, 290, '🃏 Charaktere', () => this.scene.start('Characters'));
    button(this, 480, 360, '🔑 Code einlösen', () => this.scene.start('Redeem'));
    button(this, 480, 430, '🛒 Lehrerzimmer-Shop', () => this.scene.start('Shop'));

    const c = getCharacter(save.selected);
    const img = this.add.image(800, 330, portraitKey(this, c));
    img.setScale(Math.min(140 / img.width, 180 / img.height));
    this.add.text(800, 440, c.name, { fontFamily: FONT, fontSize: '20px', color: '#fff' }).setOrigin(0.5);
    this.add.text(20, 20, `🪙 ${save.coins} ALX-Taler`, { fontFamily: FONT, fontSize: '22px', color: '#ffd700' });
    this.add.text(940, 20, `${save.unlocked.length - 1}/20 Lehrer`, { fontFamily: FONT, fontSize: '20px', color: '#fff' }).setOrigin(1, 0);
    if (isTestMode) this.add.text(480, 525, 'TESTMODUS (kein Server verbunden)', { fontFamily: FONT, fontSize: '14px', color: '#ff7777' }).setOrigin(0.5);
  }
}
