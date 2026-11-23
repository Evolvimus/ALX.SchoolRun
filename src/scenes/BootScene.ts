import Phaser from 'phaser';
import { ALL_CHARACTERS } from '../data/characters';
import { fetchUnlocks } from '../services/backend';
import { unlock } from '../services/save';

export class BootScene extends Phaser.Scene {
  constructor() { super('Boot'); }

  preload() {
    this.load.json('manifest', 'characters/manifest.json');
  }

  create() {
    this.makePlaceholders();
    // Echte Lehrerbilder laden, die in public/characters/manifest.json eingetragen sind
    const ids: string[] = this.cache.json.get('manifest') ?? [];
    ids.forEach(id => this.load.image(`img-${id}`, `characters/${id}.png`));
    this.load.once('complete', () => {
      fetchUnlocks().then(list => list.forEach(unlock)).catch(() => {});
      this.scene.start('Menu');
    });
    this.load.start();
  }

  private makePlaceholders() {
    const g = this.add.graphics();
    for (const c of ALL_CHARACTERS) {
      g.clear();
      g.fillStyle(c.color).fillRoundedRect(4, 18, 32, 34, 6);       // Körper
      g.fillStyle(0xffd9b3).fillCircle(20, 12, 11);                 // Kopf
      g.fillStyle(0x000000).fillCircle(16, 11, 2).fillCircle(24, 11, 2);
      g.fillStyle(0x333333).fillRect(8, 52, 9, 8).fillRect(23, 52, 9, 8); // Beine
      g.generateTexture(`char-${c.id}`, 40, 60);
    }
    g.clear(); g.fillStyle(0x6b8e23).fillRect(0, 0, 45, 45); g.fillStyle(0x8b5a2b).fillRect(0, 8, 45, 37);
    g.lineStyle(2, 0x5a3a1a).strokeRect(0, 0, 45, 45); g.generateTexture('ground', 45, 45);
    g.clear(); g.fillStyle(0x9aa4c7).fillRect(0, 0, 45, 18); g.lineStyle(2, 0x58607f).strokeRect(0, 0, 45, 18);
    g.generateTexture('platform', 45, 18);
    g.clear(); g.fillStyle(0xc68642).fillRect(0, 0, 45, 45); g.lineStyle(4, 0x7a4b1f).strokeRect(2, 2, 41, 41)
      .lineBetween(2, 2, 43, 43).lineBetween(43, 2, 2, 43); g.generateTexture('crate', 45, 45);
    g.clear(); g.fillStyle(0xffd700).fillCircle(12, 12, 11); g.fillStyle(0xffef80).fillCircle(9, 9, 4);
    g.generateTexture('coin', 24, 24);
    g.clear(); g.fillStyle(0xdddddd);
    for (let i = 0; i < 3; i++) g.fillTriangle(i * 15, 45, i * 15 + 7.5, 22, i * 15 + 15, 45);
    g.generateTexture('spikes', 45, 45);
    g.clear(); g.fillStyle(0xffffff).fillTriangle(0, 10, 40, 0, 40, 20); g.lineStyle(2, 0x999999).strokeTriangle(0, 10, 40, 0, 40, 20);
    g.generateTexture('plane', 40, 20);
    g.clear(); g.fillStyle(0x444444).fillRect(0, 0, 6, 135); g.fillStyle(0xffcc33).fillTriangle(6, 0, 60, 20, 6, 40);
    g.generateTexture('flag', 60, 135);
    g.clear(); g.fillStyle(0xffffff, 0.25).fillCircle(45, 45, 45); g.generateTexture('touch', 90, 90);
    g.destroy();
  }
}
