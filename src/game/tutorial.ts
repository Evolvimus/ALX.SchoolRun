// Tutorial: zeigt Schritt für Schritt Aufgaben an und öffnet Türen, sobald eine Aufgabe erledigt ist.
import Phaser from 'phaser';
import type { GameScene } from '../scenes/GameScene';
import { TutorialStep } from '../data/levels';
import { FONT } from '../scenes/ui';
import { sfx } from '../services/audio';

const T = 45;

export interface Door { zone: Phaser.GameObjects.Zone; img: Phaser.GameObjects.Image; open: boolean; }

export class Tutorial {
  private index = 0;
  private shownAt = 0;
  private doneAt = 0;
  private box: Phaser.GameObjects.Rectangle;
  private text: Phaser.GameObjects.Text;
  private check: Phaser.GameObjects.Image;
  private keys: Record<string, string>;
  /** Welche Gegnerarten in diesem Durchlauf besiegt wurden ('' = Übungsscheibe) */
  defeated = new Set<string>();

  /** Am PC unten über dem dunklen Boden, am Handy oben (unten liegen die Touch-Buttons) */
  readonly y: number;

  constructor(private scene: GameScene, private steps: TutorialStep[], private doors: Door[], touch: boolean) {
    this.y = touch ? 122 : 466;
    this.keys = touch
      ? { LAUFEN: '< >', SPRINGEN: '^', HIEB: 'X' }
      : { LAUFEN: 'PFEILTASTEN', SPRINGEN: 'LEERTASTE', HIEB: 'X' };
    this.box = scene.add.rectangle(480, this.y, 640, 70, 0x0b0b0d, 0.88).setStrokeStyle(3, 0xffcc33).setScrollFactor(0).setDepth(25);
    this.text = scene.add.text(480, this.y, '', { fontFamily: FONT, fontSize: '12px', color: '#ffffff', align: 'center', lineSpacing: 9 })
      .setOrigin(0.5).setScrollFactor(0).setDepth(26);
    this.check = scene.add.image(0, this.y, 'check').setScrollFactor(0).setDepth(26).setVisible(false);
    this.show(0);
  }

  private fill(t: string) { return t.replace(/\{(\w+)\}/g, (_, k: string) => this.keys[k] ?? k); }

  private show(i: number) {
    this.index = i;
    this.doneAt = 0;
    this.check.setVisible(false);
    const step = this.steps[i];
    const visible = !!step;
    this.box.setVisible(visible); this.text.setVisible(visible);
    if (!step) return;
    this.text.setText(this.fill(step.text)).setColor('#ffffff');
    this.box.setSize(Math.max(420, this.text.width + 110), this.text.height + 30);
    this.box.setStrokeStyle(3, 0xffcc33);
    this.shownAt = this.scene.time.now;
    this.box.setScale(0.9); this.text.setScale(0.9);
    this.scene.tweens.add({ targets: [this.box, this.text], scale: 1, duration: 220, ease: 'Back.Out' });
  }

  private isDone(step: TutorialStep, time: number) {
    const d = step.done, s = this.scene;
    switch (d.type) {
      case 'col': return s.player.x > d.col * T;
      case 'leaves': return s.leavesCollected >= d.count;
      case 'checkpoint': return s.checkpointReached;
      case 'defeat': return this.defeated.has(d.kind);
      case 'timer': return time - this.shownAt > d.ms;
      case 'goal': return false;
    }
  }

  update(time: number) {
    const step = this.steps[this.index];
    if (!step) return;
    const next = this.steps[this.index + 1];
    // Wer eine Aufgabe ohne Tür überspringt, bekommt einfach die nächste angezeigt
    if (!this.doneAt && !step.opensDoor && next && this.scene.player.x > next.at * T + T) { this.show(this.index + 1); return; }
    if (!this.doneAt && this.scene.player.x < step.at * T) return;
    if (!this.doneAt && this.isDone(step, time)) {
      this.doneAt = time;
      sfx.checkpoint();
      this.text.setColor('#a6ff8a');
      this.box.setStrokeStyle(3, 0x6cff6c);
      this.check.setPosition(480 - this.box.width / 2 + 30, this.y).setVisible(true).setScale(1.2);
      if (step.opensDoor) this.openNextDoor();
    }
    if (this.doneAt && time - this.doneAt > 900) this.show(this.index + 1);
  }

  hide() { this.box.setVisible(false); this.text.setVisible(false); this.check.setVisible(false); }

  private openNextDoor() {
    const door = this.doors.find(d => !d.open);
    if (!door) return;
    door.open = true;
    door.img.setTexture('door-open');
    this.scene.time.delayedCall(250, () => {
      door.zone.destroy();
      this.scene.fx.dust(door.img.x, door.img.y, 10);
      this.scene.tweens.add({ targets: door.img, y: door.img.y - 190, alpha: 0.15, duration: 600, ease: 'Cubic.In' });
    });
  }
}
