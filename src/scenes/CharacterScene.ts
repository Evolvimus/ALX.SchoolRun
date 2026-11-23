import Phaser from 'phaser';
import { backButton, card, FONT, title } from './ui';
import { ALL_CHARACTERS, ABILITY_LABEL, RARITY_LABEL } from '../data/characters';
import { persist, save } from '../services/save';

export class CharacterScene extends Phaser.Scene {
  constructor() { super('Characters'); }
  create() {
    title(this, 'Sammelalbum', 36);
    const info = this.add.text(560, 500, 'Tippe einen freigeschalteten Charakter an', { fontFamily: FONT, fontSize: '18px', color: '#fff' }).setOrigin(0.5);
    ALL_CHARACTERS.forEach((c, i) => {
      const x = 75 + (i % 11) * 82, y = 160 + Math.floor(i / 11) * 165;
      const unlocked = save.unlocked.includes(c.id);
      const k = card(this, x, y, c, unlocked, 0.7).setInteractive({ useHandCursor: true });
      if (c.id === save.selected) this.add.rectangle(x, y, 84, 112).setStrokeStyle(4, 0xffffff);
      k.on('pointerup', () => {
        if (!unlocked) { info.setText(`🔒 ${RARITY_LABEL[c.rarity]} – per Karten-Code oder im Shop freischalten`); return; }
        save.selected = c.id; persist(); this.scene.restart();
      });
      k.on('pointerover', () => unlocked && info.setText(`${c.name} (${c.subject}) · ${RARITY_LABEL[c.rarity]} · Fähigkeit: ${ABILITY_LABEL[c.ability]}`));
    });
    backButton(this);
  }
}
