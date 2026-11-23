import Phaser from 'phaser';
import { backButton, FONT, menuBackground, title } from './ui';
import { LEVELS, countLeaves } from '../data/levels';
import { save } from '../services/save';
import { sfx } from '../services/audio';

export class LevelSelectScene extends Phaser.Scene {
  constructor() { super('Levels'); }
  create() {
    menuBackground(this);
    title(this, 'Level wählen', 44);
    LEVELS.forEach((lv, i) => {
      const x = 480 + (i - (LEVELS.length - 1) / 2) * 290, y = 270;
      const open = i <= save.progress;
      const total = countLeaves(lv), got = save.bestLeaves[lv.id] ?? 0, best = save.bestTimes[lv.id];
      const frame = this.add.rectangle(x, y, 260, 310, 0x14172e).setStrokeStyle(4, open ? 0xffcc33 : 0x444a66);
      this.add.tileSprite(x, y - 70, 240, 135, lv.bg).setTileScale(1 / 3).setTilePosition(40, 0).setAlpha(open ? 1 : 0.35);
      this.add.text(x, y + 22, `${i + 1}`, { fontFamily: FONT, fontSize: '26px', color: open ? '#ffcc33' : '#666c88' }).setOrigin(0.5);
      this.add.text(x, y + 56, lv.name, { fontFamily: FONT, fontSize: '13px', color: open ? '#fff' : '#666c88' }).setOrigin(0.5);
      if (!open) {
        this.add.text(x, y + 104, 'Gesperrt', { fontFamily: FONT, fontSize: '11px', color: '#666c88' }).setOrigin(0.5);
        return;
      }
      this.add.image(x - 66, y + 92, 'leaf').setScale(0.7);
      this.add.text(x - 48, y + 86, `${got}/${total}${got >= total ? '  ALLE!' : ''}`, { fontFamily: FONT, fontSize: '11px', color: '#ffd23f' });
      this.add.text(x, y + 124, best ? `Bestzeit ${best.toFixed(1)}s` : 'Noch nicht geschafft', { fontFamily: FONT, fontSize: '10px', color: '#c8c8d8' }).setOrigin(0.5);
      frame.setInteractive({ useHandCursor: true });
      frame.on('pointerover', () => frame.setFillStyle(0x20254a));
      frame.on('pointerout', () => frame.setFillStyle(0x14172e));
      frame.on('pointerup', () => { sfx.click(); this.scene.start('Game', { level: i }); });
    });
    backButton(this);
  }
}
