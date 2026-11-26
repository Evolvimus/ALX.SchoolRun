import Phaser from 'phaser';
import type { GameScene } from '../scenes/GameScene';
import { Character, hasAbility } from '../data/characters';
import { FONT, portraitKey } from '../scenes/ui';
import { sfx } from '../services/audio';

export interface Controls { left: boolean; right: boolean; jump: boolean; attack: boolean; }
export const NO_CONTROLS: Controls = { left: false, right: false, jump: false, attack: false };

const approach = (v: number, target: number, step: number) => (v < target ? Math.min(v + step, target) : Math.max(v - step, target));

/**
 * Spielfigur: unsichtbarer Physik-Körper + sichtbares Bild, das ihm folgt.
 * So kann das Bild gestaucht/gestreckt werden, ohne die Kollision zu verändern.
 */
export class Player {
  zone: Phaser.GameObjects.Zone;
  body: Phaser.Physics.Arcade.Body;
  view: Phaser.GameObjects.Sprite;
  private ruler: Phaser.GameObjects.Image;
  private bubble?: Phaser.GameObjects.Text;
  private bubbleUntil = 0;
  private nextQuote = 0;
  private quoteIndex = 0;
  private nextSparkle = 0;
  private reach: number;

  facing = 1;
  lives = 3;
  safeUntil = 0;
  swingId = 0;
  /** Von Gegnern pro Frame gesetzt: Wind (Zielgeschwindigkeit) und Kraft (Beschleunigung). */
  windTarget = 0;
  force = new Phaser.Math.Vector2();

  private vx = 0;
  private extVx = 0;
  private lockUntil = 0;
  private attackUntil = 0;
  private nextAttack = 0;
  private lastGround = -9999;
  private bufferUntil = 0;
  private prevJump = false;
  private prevAttack = false;
  private jumping = false;
  private airJumps = 0;
  private wasGround = true;
  private fallSpeed = 0;
  private squash = { x: 1, y: 1 };
  private baseKey: string;
  private animated: boolean;
  private baseScale: number;

  constructor(private scene: GameScene, x: number, y: number, public char: Character) {
    this.zone = scene.add.zone(x, y, 26, 52);
    scene.physics.add.existing(this.zone);
    this.body = this.zone.body as Phaser.Physics.Arcade.Body;
    this.body.setMaxVelocity(2000, 1000);
    this.baseKey = portraitKey(scene, char);
    this.animated = this.baseKey.startsWith('char-');
    this.view = scene.add.sprite(x, y, this.baseKey).setOrigin(0.5, 1).setDepth(10);
    this.baseScale = 60 / this.view.height;
    const weapon = char.weapon === 'goldHammer' ? 'hammer-gold' : char.weapon === 'hammer' ? 'hammer' : 'ruler';
    this.reach = char.weapon === 'goldHammer' ? 90 : 70;
    this.ruler = scene.add.image(x, y, weapon).setOrigin(0.08, 0.5).setDepth(11).setVisible(false);
    if (char.weapon === 'goldHammer') this.ruler.setScale(1.25);
    this.quoteIndex = Math.floor(Math.random() * (char.quotes?.length ?? 1));
    this.nextQuote = scene.time.now + 900;
  }

  get x() { return this.body.center.x; }
  get y() { return this.body.center.y; }
  get onGround() { return this.body.blocked.down || this.body.touching.down; }
  rect() { return new Phaser.Geom.Rectangle(this.body.x, this.body.y, this.body.width, this.body.height); }

  /** Trefferzone des Lineals, solange der Hieb aktiv ist. */
  attackRect(time: number) {
    if (time >= this.attackUntil) return null;
    return new Phaser.Geom.Rectangle(this.facing > 0 ? this.x - 4 : this.x - this.reach + 4, this.body.y - 16, this.reach, this.body.height + 20);
  }

  update(time: number, deltaMs: number, c: Controls) {
    const dt = Math.min(deltaMs, 34) / 1000, b = this.body;
    const ground = this.onGround;
    const locked = time < this.lockUntil;
    const maxSpeed = hasAbility(this.char, 'speed') ? 400 : 300;
    const jumpV = hasAbility(this.char, 'highJump') ? -780 : -640;

    // Landen
    if (ground && !this.wasGround && this.fallSpeed > 260) {
      this.squashTo(1.18, 0.82);
      this.scene.fx.dust(this.x, b.bottom, 5);
      sfx.land();
    }
    if (ground) { this.lastGround = time; this.airJumps = hasAbility(this.char, 'doubleJump') ? 1 : 0; }
    this.wasGround = ground;
    this.fallSpeed = b.velocity.y;

    // Laufen mit Beschleunigung und Bremsen
    const dir = locked ? 0 : (c.right ? 1 : 0) - (c.left ? 1 : 0);
    if (dir) {
      if (ground && Math.sign(this.vx) === -dir && Math.abs(this.vx) > 150) this.scene.fx.dust(this.x, b.bottom, 2);
      this.vx = approach(this.vx, dir * maxSpeed, (ground ? 2600 : 1900) * dt);
      this.facing = dir;
    } else if (!locked) {
      this.vx = approach(this.vx, 0, (ground ? 3000 : 900) * dt);
    }
    if ((b.blocked.left && this.vx < 0) || (b.blocked.right && this.vx > 0)) this.vx = 0;

    // Springen: Sprungpuffer + Coyote Time + variable Höhe
    const pressed = c.jump && !this.prevJump;
    if (pressed) this.bufferUntil = time + 130;
    if (!locked && time < this.bufferUntil && time - this.lastGround < 110) {
      this.jump(jumpV); sfx.jump();
    } else if (!locked && pressed && !ground && this.airJumps > 0) {
      this.airJumps--; this.jump(jumpV * 0.92); sfx.airJump();
    }
    if (this.jumping && !c.jump && b.velocity.y < -240) { b.setVelocityY(b.velocity.y * 0.5); this.jumping = false; }
    if (b.velocity.y >= 0) this.jumping = false;
    if (hasAbility(this.char, 'glide') && c.jump && b.velocity.y > 120) b.setVelocityY(120);
    this.prevJump = c.jump;

    // Äußere Einflüsse: Wind und Magnetkraft
    this.extVx += this.force.x * dt;
    this.extVx = this.windTarget ? approach(this.extVx, this.windTarget, 1500 * dt) : approach(this.extVx, 0, 520 * dt);
    b.velocity.y += this.force.y * dt;
    b.setVelocityX(this.vx + this.extVx);

    // Lineal-Hieb
    if (!locked && c.attack && !this.prevAttack && time >= this.nextAttack) {
      this.swingId++;
      this.attackUntil = time + 150;
      this.nextAttack = time + 320;
      sfx.swing();
    }
    this.prevAttack = c.attack;

    // Sprüche: kurz nach dem Start und danach ab und zu
    const quotes = this.char.quotes;
    if (quotes?.length && time >= this.nextQuote) {
      this.say(quotes[this.quoteIndex++ % quotes.length], time);
      this.nextQuote = time + Phaser.Math.Between(22000, 32000);
    }
    // Mythisch: Glitzer-Spur
    if (this.char.rarity === 'mythisch' && time >= this.nextSparkle && (dir !== 0 || !ground)) {
      this.nextSparkle = time + 60;
      this.scene.fx.burst(this.x + Phaser.Math.Between(-8, 8), this.y + Phaser.Math.Between(-20, 20), Math.random() < 0.5 ? 0xffd84a : 0xff7fbf, 1);
    }

    this.draw(time, ground, dir !== 0);
  }

  /** Sprechblase über dem Kopf. */
  say(text: string, time: number, ms = 3200) {
    this.bubble?.destroy();
    this.bubble = this.scene.add.text(this.x, this.body.y - 14, text, {
      fontFamily: FONT, fontSize: '9px', color: '#1a1a2e', align: 'center', lineSpacing: 4,
      backgroundColor: '#ffffffee', padding: { x: 7, y: 6 },
    }).setOrigin(0.5, 1).setDepth(17);
    this.bubbleUntil = time + ms;
  }

  private jump(v: number) {
    this.body.setVelocityY(v);
    this.lastGround = -9999; this.bufferUntil = 0; this.jumping = true;
    this.squashTo(0.86, 1.16);
    this.scene.fx.dust(this.x, this.body.bottom, 3);
  }

  /** Hochfedern (Matte, Ball, besiegter Gegner) – wird nicht durch Loslassen der Taste gekürzt. */
  bounce(v: number) {
    this.body.setVelocityY(v);
    this.jumping = false;
    this.airJumps = hasAbility(this.char, 'doubleJump') ? 1 : 0;
    this.squashTo(0.82, 1.2);
    sfx.bounce();
  }

  /** Treffer einstecken. Gibt true zurück, wenn wirklich ein Leben verloren ging. */
  hurt(time: number, fromX: number) {
    if (time < this.safeUntil) return false;
    this.lives--;
    this.safeUntil = time + 1500;
    this.lockUntil = time + 260;
    this.vx = (this.x < fromX ? -1 : 1) * 260;
    this.body.setVelocityY(-380);
    return true;
  }

  respawn(time: number, x: number, y: number) {
    this.body.reset(x, y);
    this.vx = this.extVx = 0;
    this.safeUntil = time + 1500;
  }

  stop() { this.vx = approach(this.vx, 0, 60); }

  private squashTo(x: number, y: number) {
    this.squash.x = x; this.squash.y = y;
    this.scene.tweens.add({ targets: this.squash, x: 1, y: 1, duration: 180, ease: 'Sine.Out' });
  }

  private draw(time: number, ground: boolean, moving: boolean) {
    const b = this.body, v = this.view;
    v.setPosition(b.center.x, b.bottom + 1);
    if (this.animated) {
      const frame = !ground ? '-j' : moving ? (Math.floor(time / 95) % 2 ? '-w1' : '-w2')
        : (Math.floor(time / 520) % 2 && this.scene.textures.exists(this.baseKey + '-i') ? '-i' : '');
      v.setTexture(this.baseKey + frame);
    } else {
      v.setAngle(!ground ? this.facing * 6 : moving ? Math.sin(time / 55) * 4 : 0);
    }
    v.setFlipX(this.facing < 0);
    v.setScale(this.baseScale * this.squash.x, this.baseScale * this.squash.y);
    v.setAlpha(time < this.safeUntil && Math.floor(time / 80) % 2 ? 0.3 : 1);

    if (this.bubble) {
      if (time >= this.bubbleUntil) { this.bubble.destroy(); this.bubble = undefined; }
      else this.bubble.setPosition(b.center.x, b.y - 14);
    }

    const swinging = time < this.attackUntil;
    this.ruler.setVisible(swinging);
    if (swinging) {
      const p = 1 - (this.attackUntil - time) / 150;
      const a = Phaser.Math.Linear(-115, 40, p);
      this.ruler.setPosition(b.center.x + this.facing * 6, b.center.y - 6).setAngle(this.facing > 0 ? a : 180 - a);
    }
  }
}
