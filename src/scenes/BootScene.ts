import Phaser from 'phaser';
import { makePixelTextures } from './pixelArt';
import { fetchUnlocks } from '../services/backend';
import { unlock } from '../services/save';

export class BootScene extends Phaser.Scene {
  constructor() { super('Boot'); }

  preload() {
    this.load.json('manifest', 'characters/manifest.json');
  }

  create() {
    makePixelTextures(this);
    // Echte Lehrerbilder laden, die in public/characters/manifest.json eingetragen sind
    const ids: string[] = this.cache.json.get('manifest') ?? [];
    ids.forEach(id => this.load.image(`img-${id}`, `characters/${id}.png`));
    this.load.once('complete', () => {
      fetchUnlocks().then(list => list.forEach(unlock)).catch(() => {});
      document.fonts.load('16px "Press Start 2P"').finally(() => this.scene.start('Menu'));
    });
    this.load.start();
  }

}
