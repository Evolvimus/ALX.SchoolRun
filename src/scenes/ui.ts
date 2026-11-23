import Phaser from 'phaser';
import { Character, RARITY_COLOR } from '../data/characters';
import { sfx } from '../services/audio';

export const FONT = '"Press Start 2P", monospace';

/** Pixel-Schulhintergrund, abgedunkelt, für Menüs. */
export function menuBackground(scene: Phaser.Scene) {
  scene.add.tileSprite(480, 202.5, 960, 405, 'bg-school').setTilePosition(Math.random() * 1920, 0);
  scene.add.rectangle(480, 472, 960, 135, 0x6b4426);
  scene.add.rectangle(480, 270, 960, 540, 0x10132b, 0.6);
}

export function button(scene: Phaser.Scene, x: number, y: number, label: string, onClick: () => void, w = 320) {
  const bg = scene.add.rectangle(0, 0, w, 56, 0xffcc33).setStrokeStyle(4, 0x7a4b00);
  const txt = scene.add.text(0, 0, label, { fontFamily: FONT, fontSize: '15px', color: '#2b1a00', fontStyle: 'bold' }).setOrigin(0.5);
  const c = scene.add.container(x, y, [bg, txt]).setSize(w, 56).setInteractive({ useHandCursor: true });
  c.on('pointerover', () => bg.setFillStyle(0xffe080));
  c.on('pointerout', () => bg.setFillStyle(0xffcc33));
  c.on('pointerup', () => { sfx.click(); onClick(); });
  return c;
}

export function title(scene: Phaser.Scene, text: string, y = 50) {
  return scene.add.text(480, y, text, { fontFamily: FONT, fontSize: '25px', color: '#ffcc33', fontStyle: 'bold' })
    .setOrigin(0.5).setStroke('#000', 6);
}

export function backButton(scene: Phaser.Scene) {
  return button(scene, 90, 500, '← Zurück', () => scene.scene.start('Menu'), 150);
}

/** Bild des Charakters: echtes Bild falls vorhanden, sonst Platzhalter. */
export function portraitKey(scene: Phaser.Scene, c: Character) {
  return scene.textures.exists(`img-${c.id}`) ? `img-${c.id}` : `char-${c.id}`;
}

export function card(scene: Phaser.Scene, x: number, y: number, c: Character, unlocked: boolean, scale = 1) {
  const items: Phaser.GameObjects.GameObject[] = [];
  items.push(scene.add.rectangle(0, 0, 110, 150, 0x2a2f5a).setStrokeStyle(5, RARITY_COLOR[c.rarity]));
  const img = scene.add.image(0, -15, portraitKey(scene, c));
  img.setScale(Math.min(90 / img.width, 95 / img.height));
  if (!unlocked) img.setTintFill(0x111111);
  items.push(img);
  items.push(scene.add.text(0, 55, unlocked ? c.name : '???', {
    fontFamily: FONT, fontSize: '9px', color: '#fff', align: 'center', wordWrap: { width: 104 },
  }).setOrigin(0.5));
  return scene.add.container(x, y, items).setSize(110, 150).setScale(scale);
}
