import Phaser from 'phaser';
import { backButton, FONT, menuBackground, title } from './ui';
import { BESTIARY, BeastInfo } from '../data/bestiary';
import { save } from '../services/save';
import { sfx } from '../services/audio';

/** Gegner-Lexikon: Welche Gegner hat man schon entdeckt? Unentdeckte erscheinen als Silhouette. */
export class LexikonScene extends Phaser.Scene {
  private detail!: Phaser.GameObjects.Container;
  private frames: Phaser.GameObjects.Rectangle[] = [];

  constructor() { super('Lexikon'); }

  create() {
    menuBackground(this);
    const found = BESTIARY.filter(b => save.seen.includes(b.id)).length;
    title(this, 'Gegner-Lexikon', 38);
    this.add.text(480, 76, `${found} von ${BESTIARY.length} entdeckt`, { fontFamily: FONT, fontSize: '11px', color: '#c8c8d8' }).setOrigin(0.5);
    // Fortschrittsbalken
    this.add.rectangle(480, 94, 300, 8, 0x2a2f5a).setStrokeStyle(2, 0x0b0b0d);
    if (found) this.add.rectangle(330, 94, 300 * found / BESTIARY.length, 8, 0x5ab0ff).setOrigin(0, 0.5);

    this.frames = [];
    BESTIARY.forEach((b, i) => {
      const x = 480 + ((i % 4) - 1.5) * 222, y = 172 + Math.floor(i / 4) * 128;
      const known = save.seen.includes(b.id);
      const frame = this.add.rectangle(x, y, 206, 116, 0x14172e).setStrokeStyle(3, known ? 0x5ab0ff : 0x3a3f5e);
      this.frames.push(frame);
      const icon = this.add.image(x - 52, y - 2, b.icon);
      icon.setScale(Math.min(b.scale, 86 / icon.width, 80 / icon.height));
      if (!known) icon.setTintFill(0x05060f).setAlpha(0.85);
      this.add.text(x - 2, y - 30, known ? b.name : '???', { fontFamily: FONT, fontSize: '10px', color: known ? '#ffffff' : '#666c88', wordWrap: { width: 100 } });
      if (known) {
        const n = save.defeated[b.id] ?? 0;
        this.add.text(x - 2, y + 18, b.defeatable ? `Besiegt: ${n}` : 'Unbesiegbar', { fontFamily: FONT, fontSize: '8px', color: b.defeatable ? '#ffd23f' : '#ff8a8a' });
      } else {
        this.add.text(x - 2, y + 18, 'Noch nicht\nentdeckt', { fontFamily: FONT, fontSize: '8px', color: '#666c88', lineSpacing: 4 });
      }
      frame.setInteractive({ useHandCursor: true });
      frame.on('pointerover', () => frame.setFillStyle(0x20254a));
      frame.on('pointerout', () => frame.setFillStyle(0x14172e));
      frame.on('pointerup', () => { sfx.click(); this.showDetail(i, b, known); });
    });

    this.detail = this.add.container(0, 0);
    const first = BESTIARY.findIndex(b => save.seen.includes(b.id));
    if (first >= 0) this.showDetail(first, BESTIARY[first], true);
    else this.showDetail(-1, null, false);
    backButton(this);
  }

  private showDetail(i: number, b: BeastInfo | null, known: boolean) {
    this.frames.forEach((f, k) => f.setStrokeStyle(3, k === i ? 0xffcc33 : save.seen.includes(BESTIARY[k].id) ? 0x5ab0ff : 0x3a3f5e));
    this.detail.removeAll(true);
    const add = <T extends Phaser.GameObjects.GameObject>(o: T) => { this.detail.add(o); return o; };
    add(this.add.rectangle(560, 432, 760, 112, 0x0b0b0d, 0.9).setStrokeStyle(3, 0xffcc33));
    if (!b || !known) {
      add(this.add.text(560, 432, b ? 'Diesen Gegner hast du noch nicht gesehen.\nSpiel weiter, um ihn zu entdecken!' : 'Noch keine Gegner entdeckt.\nSpiel das Tutorial oder Level 1!',
        { fontFamily: FONT, fontSize: '11px', color: '#c8c8d8', align: 'center', lineSpacing: 8 }).setOrigin(0.5));
      return;
    }
    const style = { fontFamily: FONT, fontSize: '9px', color: '#ffffff', lineSpacing: 6, wordWrap: { width: 590 } };
    add(this.add.text(196, 386, b.name.toUpperCase(), { fontFamily: FONT, fontSize: '13px', color: '#ffcc33' }));
    add(this.add.text(924, 388, b.where, { fontFamily: FONT, fontSize: '8px', color: '#9a9aa8' }).setOrigin(1, 0));
    add(this.add.text(196, 410, b.behavior, style));
    add(this.add.text(196, 448, `TIPP: ${b.tip}`, { ...style, color: '#a6e07a' }));
  }
}
