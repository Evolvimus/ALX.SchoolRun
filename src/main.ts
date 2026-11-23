import Phaser from 'phaser';
import '@fontsource/press-start-2p/400.css';
import { BootScene } from './scenes/BootScene';
import { MenuScene } from './scenes/MenuScene';
import { CharacterScene } from './scenes/CharacterScene';
import { RedeemScene } from './scenes/RedeemScene';
import { ShopScene } from './scenes/ShopScene';
import { GameScene } from './scenes/GameScene';

new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#1b1f3b',
  pixelArt: true,
  roundPixels: true,
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH, width: 960, height: 540 },
  physics: { default: 'arcade', arcade: { gravity: { x: 0, y: 1400 }, debug: false } },
  input: { activePointers: 4 },
  scene: [BootScene, MenuScene, CharacterScene, RedeemScene, ShopScene, GameScene],
});
