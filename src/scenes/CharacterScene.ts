import Phaser from 'phaser';
import { backButton, card, FONT, title, menuBackground } from './ui';
import { ALL_CHARACTERS, abilityText, Character, getCharacter, RARITY_LABEL } from '../data/characters';
import { persist, save } from '../services/save';

export class CharacterScene extends Phaser.Scene {
  constructor() { super('Characters'); }
  create() {
    menuBackground(this);
    title(this, 'Sammelalbum', 36);
    const describe = (c: Character) => `${c.name} (${c.subject}) · ${RARITY_LABEL[c.rarity]}\nFähigkeit: ${abilityText(c)}`;
    const info = this.add.text(560, 498, describe(getCharacter(save.selected)), { fontFamily: FONT, fontSize: '10px', color: '#fff', align: 'center', lineSpacing: 6 }).setOrigin(0.5);
    ALL_CHARACTERS.forEach((c, i) => {
      const x = 75 + (i % 11) * 82, y = 160 + Math.floor(i / 11) * 165;
      const unlocked = save.unlocked.includes(c.id);
      const k = card(this, x, y, c, unlocked, 0.7).setInteractive({ useHandCursor: true });
      if (c.id === save.selected) this.add.rectangle(x, y, 84, 112).setStrokeStyle(4, 0xffffff);
      k.on('pointerup', () => {
        if (!unlocked) { info.setText(c.price ? `🔒 ${RARITY_LABEL[c.rarity]} – per Karten-Code oder im Shop freischalten` : `🔒 ${RARITY_LABEL[c.rarity]} – nur per Karten-Code`); return; }
        save.selected = c.id; persist(); this.scene.restart();
      });
      k.on('pointerover', () => unlocked && info.setText(describe(c)));
      k.on('pointerout', () => info.setText(describe(getCharacter(save.selected))));
    });
    backButton(this);
  }
}
