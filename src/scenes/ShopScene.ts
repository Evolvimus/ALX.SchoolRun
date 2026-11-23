import Phaser from 'phaser';
import { backButton, card, FONT, title } from './ui';
import { TEACHERS } from '../data/characters';
import { isShopOpen } from '../services/backend';
import { persist, save, unlock } from '../services/save';

export class ShopScene extends Phaser.Scene {
  constructor() { super('Shop'); }
  async create() {
    title(this, 'Lehrerzimmer-Shop', 36);
    const coins = this.add.text(940, 20, `🪙 ${save.coins}`, { fontFamily: FONT, fontSize: '22px', color: '#ffd700' }).setOrigin(1, 0);
    backButton(this);
    const loading = this.add.text(480, 270, 'Lade …', { fontFamily: FONT, fontSize: '22px', color: '#fff' }).setOrigin(0.5);
    const open = await isShopOpen().catch(() => false);
    loading.destroy();
    if (!open) {
      this.add.text(480, 260, 'Der Shop öffnet nach dem Ende der Sammelkartenaktion.\nBis dahin: Karten sammeln und Codes einlösen!\n\nSammle schon mal ALX-Taler in den Levels 🪙',
        { fontFamily: FONT, fontSize: '22px', color: '#fff', align: 'center' }).setOrigin(0.5);
      return;
    }
    const locked = TEACHERS.filter(t => !save.unlocked.includes(t.id));
    if (!locked.length) { this.add.text(480, 270, 'Du hast alle Lehrer! 🏆', { fontFamily: FONT, fontSize: '28px', color: '#fff' }).setOrigin(0.5); return; }
    const info = this.add.text(560, 500, 'Kostenlos – nur mit im Spiel verdienten ALX-Talern', { fontFamily: FONT, fontSize: '16px', color: '#fff' }).setOrigin(0.5);
    locked.forEach((t, i) => {
      const x = 75 + (i % 11) * 82, y = 150 + Math.floor(i / 11) * 175;
      const k = card(this, x, y, t, false, 0.7).setInteractive({ useHandCursor: true });
      this.add.text(x, y + 62, `🪙 ${t.price}`, { fontFamily: FONT, fontSize: '15px', color: '#ffd700' }).setOrigin(0.5);
      k.on('pointerup', () => {
        if (save.coins < t.price) { info.setText(`Dir fehlen noch ${t.price - save.coins} ALX-Taler.`); return; }
        save.coins -= t.price; persist(); unlock(t.id); coins.setText(`🪙 ${save.coins}`);
        this.scene.restart();
      });
    });
  }
}
