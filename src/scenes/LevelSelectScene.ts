import Phaser from 'phaser';
import { backButton, FONT, menuBackground, title } from './ui';
import { LEVELS, countLeaves, levelLabel } from '../data/levels';
import { save } from '../services/save';
import { sfx } from '../services/audio';

export class LevelSelectScene extends Phaser.Scene {
  constructor() { super('Levels'); }
  create() {
    menuBackground(this);
    title(this, 'Level wählen', 44);
    const step = Math.min(290, 920 / LEVELS.length), cw = step - 18;
    LEVELS.forEach((lv, i) => {
      const x = 480 + (i - (LEVELS.length - 1) / 2) * step, y = 262;
      const open = i <= Math.max(save.progress, 1);
      const total = countLeaves(lv), got = save.bestLeaves[lv.id] ?? 0, best = save.bestTimes[lv.id];
      const frame = this.add.rectangle(x, y, cw, 300, 0x14172e).setStrokeStyle(4, open ? 0xffcc33 : 0x444a66);
      this.add.tileSprite(x, y - 72, cw - 20, 130, lv.bg).setTileScale(1 / 3).setTilePosition(40, 0).setAlpha(open ? 1 : 0.35);
      const label = levelLabel(i);
      this.add.text(x, y + 16, label, { fontFamily: FONT, fontSize: label.length > 2 ? '16px' : '26px', color: open ? '#ffcc33' : '#666c88' }).setOrigin(0.5);
      this.add.text(x, y + 50, lv.name, { fontFamily: FONT, fontSize: '11px', color: open ? '#fff' : '#666c88' }).setOrigin(0.5);
      if (lv.tutorial && best === undefined) {
        const tag = this.add.text(x, y - 150, 'START HIER!', { fontFamily: FONT, fontSize: '10px', color: '#2b1a00', backgroundColor: '#a6e07a', padding: { x: 8, y: 5 } }).setOrigin(0.5);
        this.tweens.add({ targets: tag, y: y - 156, duration: 600, yoyo: true, repeat: -1, ease: 'Sine.InOut' });
      }
      if (!open) {
        this.add.text(x, y + 100, 'Gesperrt', { fontFamily: FONT, fontSize: '10px', color: '#666c88' }).setOrigin(0.5);
        return;
      }
      this.add.image(x - 50, y + 86, 'leaf').setScale(0.55);
      this.add.text(x - 32, y + 80, `${got}/${total}`, { fontFamily: FONT, fontSize: '11px', color: '#ffd23f' });
      this.add.text(x, y + 118, best ? `Bestzeit ${best.toFixed(1)}s` : 'Noch offen', { fontFamily: FONT, fontSize: '9px', color: '#c8c8d8' }).setOrigin(0.5);
      frame.setInteractive({ useHandCursor: true });
      frame.on('pointerover', () => frame.setFillStyle(0x20254a));
      frame.on('pointerout', () => frame.setFillStyle(0x14172e));
      frame.on('pointerup', () => { sfx.click(); this.scene.start('Game', { level: i }); });
    });
    backButton(this);
  }
}
