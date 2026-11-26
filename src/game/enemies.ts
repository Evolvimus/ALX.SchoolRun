// Die acht Gegner. Keine Menschen: Tiere, Pflanzen und Geräte, die von sich aus etwas „tun“.
import Phaser from 'phaser';
import type { GameScene } from '../scenes/GameScene';
import { sfx } from '../services/audio';

const Rect = Phaser.Geom.Rectangle;
type Rect = Phaser.Geom.Rectangle;
const approach = (v: number, target: number, step: number) => (v < target ? Math.min(v + step, target) : Math.max(v - step, target));

export abstract class Enemy {
  /** Kennung fürs Gegner-Lexikon (leer = taucht dort nicht auf) */
  abstract readonly kind: string;
  alive = true;
  seen = false;
  hp = 1;
  /** Mit dem Lineal treffbar */
  hittable = true;
  /** Draufspringen besiegt ihn */
  stompable = false;
  /** Draufspringen federt nur hoch */
  bouncy = false;
  /** Berührung kostet ein Leben */
  harmful = true;
  /** Bonus-Taler beim Besiegen */
  reward = 2;
  lastSwing = -1;

  constructor(protected scene: GameScene) {}
  abstract update(time: number, dt: number): void;
  /** Aktuelle Trefferfläche oder null, wenn gerade nichts zu treffen ist. */
  abstract hitbox(): Rect | null;
  protected abstract onDie(dir: number): void;
  /** Wo der Gegner gerade zu sehen ist (für das Lexikon). null = gerade unsichtbar. */
  visibleAt(): { x: number; y: number } | null { const h = this.hitbox(); return h ? { x: h.centerX, y: h.centerY } : null; }
  protected onHurt(_dir: number) {}

  hit(dir: number) {
    if (!this.alive) return;
    if (--this.hp <= 0) this.die(dir); else { sfx.hit(); this.onHurt(dir); }
  }
  stomp() { this.die(0); }
  protected die(dir: number) {
    if (!this.alive) return;
    const hb = this.hitbox();
    this.alive = false;
    this.onDie(dir);
    if (hb) this.scene.enemyDefeated(this, hb.centerX, hb.y);
  }
}

/** Staubmaus: läuft Streife und flitzt los, wenn man ihr zu nah kommt. */
export class DustMouse extends Enemy {
  readonly kind = 'mouse';
  sprite: Phaser.Physics.Arcade.Sprite;
  private dir = -1;
  private state: 'walk' | 'alert' | 'dash' = 'walk';
  private until = 0;
  private cool = 0;
  private home: number;

  constructor(scene: GameScene, x: number, y: number) {
    super(scene);
    this.stompable = true;
    this.home = x;
    this.sprite = scene.physics.add.sprite(x, y, 'mouse-0').setDepth(8);
    (this.sprite.body as Phaser.Physics.Arcade.Body).setSize(27, 18).setOffset(3, 6);
    scene.physics.add.collider(this.sprite, scene.solids);
    scene.physics.add.collider(this.sprite, scene.crates);
  }
  hitbox() { const b = this.sprite.body as Phaser.Physics.Arcade.Body; return new Rect(b.x, b.y, b.width, b.height); }

  update(time: number) {
    const b = this.sprite.body as Phaser.Physics.Arcade.Body, p = this.scene.player;
    const wall = this.dir < 0 ? b.blocked.left : b.blocked.right;
    const tooFar = this.state === 'walk' && (this.sprite.x - this.home) * this.dir > 160; // bleibt in ihrem Revier
    if (b.blocked.down && (wall || tooFar || !this.scene.solidAt(this.sprite.x + this.dir * 22, b.bottom + 8))) this.dir *= -1;

    if (this.state === 'walk' && time > this.cool && Math.abs(p.x - this.sprite.x) < 200 && Math.abs(p.y - this.sprite.y) < 60) {
      this.state = 'alert'; this.until = time + 380;
      this.dir = p.x < this.sprite.x ? -1 : 1;
      this.scene.fx.text(this.sprite.x, this.sprite.y - 22, '!', '#ff5a5a');
      this.scene.tweens.add({ targets: this.sprite, scaleY: 0.7, scaleX: 1.2, duration: 120, yoyo: true });
    } else if (this.state === 'alert' && time > this.until) {
      this.state = 'dash'; this.until = time + 650;
    } else if (this.state === 'dash' && time > this.until) {
      this.state = 'walk'; this.cool = time + 1300;
    }
    b.setVelocityX(this.dir * (this.state === 'dash' ? 220 : this.state === 'alert' ? 0 : 65));
    this.sprite.setFlipX(this.dir > 0);
    this.sprite.setTexture(Math.floor(time / (this.state === 'dash' ? 70 : 160)) % 2 ? 'mouse-1' : 'mouse-0');
    if (this.state === 'dash' && b.blocked.down && Math.floor(time / 90) % 2) this.scene.fx.dust(this.sprite.x - this.dir * 12, b.bottom, 1);
  }

  protected onDie(dir: number) {
    const s = this.sprite;
    (s.body as Phaser.Physics.Arcade.Body).enable = false;
    this.scene.fx.dust(s.x, s.y, 10);
    this.scene.tweens.add({
      targets: s, x: s.x + dir * 70, y: s.y - (dir ? 40 : 0), angle: dir * 360, scaleY: dir ? 1 : 0.2, alpha: 0,
      duration: 320, onComplete: () => s.destroy(),
    });
  }
}

/** Papierflieger: fliegen als Dreierformation durch den Raum. Ein Hieb knüllt sie zusammen. */
export class Plane extends Enemy {
  readonly kind = 'plane';
  private img: Phaser.GameObjects.Image;
  private down = false;
  private vy = 0;
  private lastT = 0;
  private static OFF_X = [0, 58, 58];
  private static OFF_Y = [0, -32, 32];

  constructor(scene: GameScene, private ox: number, private oy: number, private idx: number) {
    super(scene);
    this.reward = 1;
    this.img = scene.add.image(ox, oy, 'plane').setDepth(9);
  }
  hitbox() { return this.down || this.img.alpha < 0.6 ? null : new Rect(this.img.x - 18, this.img.y - 8, 36, 16); }

  update(time: number, dt: number) {
    const span = 780, t = (time * 0.16) % span;
    if (t < this.lastT) { this.down = false; this.img.setTexture('plane').setAngle(0); } // neue Runde
    this.lastT = t;
    if (!this.down) {
      const wave = Math.sin(t / 55 + this.idx);
      this.img.setPosition(this.ox - t + Plane.OFF_X[this.idx], this.oy + Plane.OFF_Y[this.idx] + wave * 10).setAngle(wave * 6);
      this.img.setAlpha(Phaser.Math.Clamp(Math.min(t, span - t) / 60, 0, 1));
    } else {
      this.vy += 900 * dt;
      this.img.y += this.vy * dt; this.img.x -= 40 * dt; this.img.angle += 420 * dt;
      this.img.setAlpha(Math.max(0, this.img.alpha - dt * 1.3));
    }
  }
  hit() {
    if (this.down) return;
    this.down = true; this.vy = -160;
    this.img.setTexture('paperball');
    this.scene.enemyDefeated(this, this.img.x, this.img.y - 8);
  }
  protected onDie() {}
}

/** Bücherwurm: frisst sich durchs Regal und taucht an wechselnden Löchern auf. Erst rascheln, dann schnappen. */
export class Bookworm extends Enemy {
  readonly kind = 'worm';
  private img: Phaser.GameObjects.Sprite;
  private holeImgs: Phaser.GameObjects.Image[];
  private state: 'hidden' | 'tell' | 'out' | 'back' = 'hidden';
  private until = 900;
  private f = 0; // wie weit er herausschaut (0..1)
  private hole = 0;

  constructor(scene: GameScene, private holes: { x: number; y: number }[]) {
    super(scene);
    this.hp = 2; this.reward = 5;
    this.holeImgs = holes.map(h => scene.add.image(h.x, h.y + 3, 'hole').setDepth(6));
    this.img = scene.add.sprite(0, 0, 'worm').setOrigin(0.5, 1).setDepth(7).setVisible(false);
  }
  /** Für den Testbot: wo taucht er gerade auf? */
  get active() { return this.state === 'hidden' ? null : this.holes[this.hole]; }

  hitbox() {
    if (this.f < 0.45) return null;
    const h = this.holes[this.hole], H = this.img.height * this.f;
    return new Rect(h.x - 11, h.y - H, 22, H);
  }

  update(time: number, dt: number) {
    const p = this.scene.player, h = this.holes[this.hole];
    switch (this.state) {
      case 'hidden':
        if (time > this.until) {
          const next = this.holes.map((o, i) => ({ i, d: Math.abs(o.x - p.x) }))
            .filter(o => this.holes.length === 1 || o.i !== this.hole).sort((a, b) => a.d - b.d)[0];
          if (next.d < 520) { this.hole = next.i; this.state = 'tell'; this.until = time + 700; if (this.scene.onScreen(this.holes[next.i].x)) sfx.rustle(); }
          else this.until = time + 300;
        }
        break;
      case 'tell':
        this.holeImgs[this.hole].x = h.x + Math.sin(time / 22) * 2;
        if (Math.floor(time / 110) !== Math.floor((time - dt * 1000) / 110)) this.scene.fx.burst(h.x, h.y - 2, 0xe8dcc0, 2);
        if (time > this.until) { this.holeImgs[this.hole].x = h.x; this.state = 'out'; this.until = time + 1350; }
        break;
      case 'out':
        this.f = approach(this.f, 1, dt / 0.16);
        if (time > this.until) this.state = 'back';
        break;
      case 'back':
        this.f = approach(this.f, 0, dt / 0.2);
        if (this.f <= 0) { this.state = 'hidden'; this.until = time + (this.hp < 2 ? 500 : 900 + Math.random() * 500); }
        break;
    }
    const H = this.img.height;
    this.img.setVisible(this.f > 0).setFlipX(p.x > h.x);
    if (this.f > 0) {
      this.img.setCrop(0, 0, this.img.width, H * this.f);
      this.img.setPosition(h.x + (this.state === 'out' ? Math.sin(time / 130) * 3 : 0), h.y + H * (1 - this.f));
    }
  }

  protected onHurt() {
    this.state = 'back';
    this.img.setTintFill(0xffffff);
    this.scene.time.delayedCall(90, () => this.img.clearTint());
  }
  protected onDie(dir: number) {
    const h = this.holes[this.hole];
    this.img.setCrop().setPosition(h.x, h.y).clearTint();
    this.scene.fx.burst(h.x, h.y - 20, 0xf4f4f4, 12);
    this.scene.fx.burst(h.x, h.y - 20, 0x9bc53d, 8);
    this.scene.tweens.add({ targets: this.img, x: h.x + dir * 90, y: h.y - 110, angle: dir * 540, alpha: 0, duration: 520, ease: 'Cubic.Out', onComplete: () => this.img.destroy() });
  }
}

/** Laubbläser: bläst im Takt und schiebt die Figur weg. Zwei Hiebe schalten ihn ab. */
export class Blower extends Enemy {
  readonly kind = 'blower';
  private img: Phaser.GameObjects.Image;
  on = false;
  private until = 1200;
  private nextStreak = 0;
  zone: Rect;

  constructor(scene: GameScene, private bx: number, private groundY: number, public dir: -1 | 1) {
    super(scene);
    this.hp = 2; this.harmful = false; this.reward = 5;
    this.img = scene.add.image(bx, groundY, 'blower-0').setOrigin(0.5, 1).setDepth(8).setFlipX(dir > 0);
    const len = 6 * 45;
    this.zone = new Rect(dir < 0 ? bx - 20 - len : bx + 20, groundY - 112, len, 112);
  }
  get x() { return this.bx; }
  hitbox() { return new Rect(this.bx - 22, this.groundY - 32, 44, 32); }

  update(time: number) {
    if (time > this.until) {
      this.on = !this.on;
      this.until = time + (this.on ? 2600 : 1700);
      if (this.on && this.scene.onScreen(this.bx)) sfx.blow();
    }
    const warming = !this.on && this.until - time < 450;
    this.img.setTexture(this.on && Math.floor(time / 50) % 2 ? 'blower-1' : 'blower-0');
    this.img.x = this.bx + (warming ? Math.sin(time / 18) * 1.5 : 0);
    if (!this.on) return;
    if (time > this.nextStreak && this.scene.onScreen(this.bx, 300)) {
      this.nextStreak = time + 40;
      this.scene.fx.wind(this.bx + this.dir * 26, this.groundY - 8 - Math.random() * 96, this.dir, this.zone.width - 20);
    }
    const p = this.scene.player;
    if (Rect.Overlaps(this.zone, p.rect())) p.windTarget += this.dir * 265;
  }

  protected onHurt() {
    this.scene.fx.burst(this.bx, this.groundY - 18, 0xffd23f, 8);
    this.img.setTintFill(0xffffff);
    this.scene.time.delayedCall(90, () => this.img.clearTint());
  }
  protected onDie() {
    this.on = false;
    this.img.setTexture('blower-x').clearTint();
    this.img.x = this.bx;
    this.scene.fx.burst(this.bx, this.groundY - 18, 0xffd23f, 14);
    this.scene.fx.dust(this.bx, this.groundY - 24, 12);
  }
}

/** Magnet: zieht abwechselnd an (blau) und stößt ab (rot). Kein Gegner zum Besiegen, sondern zum Ausnutzen. */
export class Magnet extends Enemy {
  readonly kind = 'magnet';
  private img: Phaser.GameObjects.Image;
  private gfx: Phaser.GameObjects.Graphics;
  static RADIUS = 250;

  constructor(scene: GameScene, public x: number, public y: number) {
    super(scene);
    this.hittable = false; this.harmful = false;
    scene.add.rectangle(x, (72 + y - 16) / 2, 3, Math.max(4, y - 16 - 72), 0x555b66).setDepth(4);
    this.gfx = scene.add.graphics().setDepth(4);
    this.img = scene.add.image(x, y, 'magnet').setDepth(8);
  }
  hitbox() { return null; }
  visibleAt() { return { x: this.x, y: this.y }; }
  protected onDie() {}

  /** +1 = zieht an, -1 = stößt ab, 0 = schaltet gerade um */
  mode(time: number) { const t = time % 6000; return t < 2600 ? 1 : t < 3000 ? 0 : t < 5600 ? -1 : 0; }
  /** Wie lange die aktuelle Phase noch dauert (ms). */
  remaining(time: number) { const t = time % 6000; return t < 2600 ? 2600 - t : t < 3000 ? 3000 - t : t < 5600 ? 5600 - t : 6000 - t; }

  update(time: number) {
    const m = this.mode(time), R = Magnet.RADIUS;
    this.gfx.clear();
    this.img.setTint(m > 0 ? 0xbfe0ff : m < 0 ? 0xffb8b8 : 0xffffff).setAlpha(m === 0 && Math.floor(time / 70) % 2 ? 0.5 : 1);
    if (m === 0) return;
    if (this.scene.onScreen(this.x, 300)) {
      for (let i = 0; i < 3; i++) {
        const k = (time / 1100 + i / 3) % 1;
        this.gfx.lineStyle(3, m > 0 ? 0x5ab0ff : 0xff5a5a, 0.4 * Math.sin(Math.PI * k));
        this.gfx.strokeCircle(this.x, this.y, R * (m > 0 ? 1 - k : k));
      }
    }
    const p = this.scene.player, dx = this.x - p.x, dy = this.y - p.y, d = Math.hypot(dx, dy);
    if (d < R && d > 1) {
      const F = 1250 * (1 - d / R) * m;
      p.force.x += (dx / d) * F * 0.6;
      p.force.y += (dy / d) * F;
    }
  }
}

/** Bunsenbrenner: aus – Zündflamme – Stichflamme. Im Aus-Takt vorbeilaufen. */
export class Burner extends Enemy {
  readonly kind = 'burner';
  private flame: Phaser.GameObjects.Image;
  private wasOn = false;
  private static CYCLE = 3400;

  constructor(scene: GameScene, public x: number, private groundY: number, private offset: number) {
    super(scene);
    this.hittable = false;
    scene.add.image(x, groundY, 'burner').setOrigin(0.5, 1).setDepth(8);
    this.flame = scene.add.image(x, groundY - 22, 'flame-0').setOrigin(0.5, 1).setDepth(7).setVisible(false);
  }
  private t(time: number) { return (time + this.offset) % Burner.CYCLE; }
  state(time: number): 'off' | 'tell' | 'on' { const t = this.t(time); return t < 1500 ? 'off' : t < 2000 ? 'tell' : 'on'; }
  /** Wie lange er noch sicher aus ist (ms); 0, wenn er an ist oder gleich zündet. */
  safeFor(time: number) { const t = this.t(time); return t < 1500 ? 1500 - t : 0; }
  private grow(time: number) { return Phaser.Math.Clamp((this.t(time) - 2000) / 120, 0, 1); }

  hitbox() {
    const time = this.scene.time.now;
    if (this.state(time) !== 'on') return null;
    const h = 86 * this.grow(time);
    return new Rect(this.x - 8, this.groundY - 22 - h, 16, h);
  }
  visibleAt() { return { x: this.x, y: this.groundY - 20 }; }
  protected onDie() {}

  update(time: number) {
    const s = this.state(time);
    if (s === 'on' && !this.wasOn && this.scene.onScreen(this.x)) sfx.flame();
    this.wasOn = s === 'on';
    this.flame.setVisible(s !== 'off').setTexture(Math.floor(time / 60) % 2 ? 'flame-1' : 'flame-0');
    if (s === 'tell') this.flame.setScale(0.5, 0.12 + (Math.floor(time / 50) % 2) * 0.05);
    else if (s === 'on') this.flame.setScale(1, this.grow(time) * (0.96 + (Math.floor(time / 60) % 2) * 0.04));
  }
}

/** Raupe: sitzt auf einem großen Ginkgoblatt und frisst es auf, sobald man in die Nähe kommt. Schnell sein! */
export class Caterpillar extends Enemy {
  readonly kind = 'caterpillar';
  private leaf: Phaser.GameObjects.Image;
  private cat: Phaser.GameObjects.Sprite;
  private eat = 0;
  private bites = 0;
  private started = false;
  private static VALUES = [5, 3, 1, 0];

  constructor(scene: GameScene, private x: number, private surfaceY: number) {
    super(scene);
    this.stompable = true; this.reward = 3;
    this.leaf = scene.add.image(x, surfaceY, 'leaf').setOrigin(0.5, 1).setScale(1.5).setDepth(6);
    this.cat = scene.add.sprite(x + 3, surfaceY - 50, 'cat-0').setOrigin(0.5, 1).setDepth(8);
  }
  hitbox() { return new Rect(this.cat.x - 15, this.cat.y - 15, 30, 15); }

  update(time: number, dt: number) {
    const p = this.scene.player;
    if (!this.started && Math.abs(p.x - this.x) < 400 && this.scene.onScreen(this.x, -40)) {
      this.started = true;
      this.scene.fx.text(this.x, this.cat.y - 26, 'Schnell!', '#ff8a5a');
    }
    this.cat.setTexture(Math.floor(time / 220) % 2 ? 'cat-1' : 'cat-0');
    if (!this.started || this.bites >= 3) return;
    this.eat += dt / 5.5;
    const b = Math.min(3, Math.floor(this.eat * 3));
    if (b > this.bites) {
      this.bites = b;
      sfx.crunch();
      this.scene.fx.burst(this.x, this.cat.y, 0xffc928, 6);
      const lh = this.leaf.height, cut = lh * 0.3 * b;
      if (b >= 3) { this.leaf.setVisible(false); this.cat.setScale(1.3); this.cat.y = this.surfaceY; }
      else { this.leaf.setCrop(0, cut, this.leaf.width, lh - cut); this.cat.y = this.surfaceY - 50 + cut * 1.5; }
    }
  }

  protected onDie(dir: number) {
    const value = Caterpillar.VALUES[this.bites];
    if (value > 0) this.scene.addLeaf(this.leaf, this.x, this.surfaceY - 22, value);
    this.scene.fx.burst(this.cat.x, this.cat.y - 6, 0x7ac74f, 10);
    this.scene.tweens.add({ targets: this.cat, x: this.cat.x + dir * 70, y: this.cat.y - 50, angle: dir * 400 || 180, alpha: 0, duration: 380, onComplete: () => this.cat.destroy() });
  }
}

/** Basketball: springt im festen Rhythmus. Von der Seite tut er weh, von oben federt er hoch. */
export class Ball extends Enemy {
  readonly kind = 'ball';
  sprite: Phaser.Physics.Arcade.Sprite;
  constructor(scene: GameScene, x: number, y: number) {
    super(scene);
    this.hittable = false; this.bouncy = true;
    this.sprite = scene.physics.add.sprite(x, y, 'ball').setScale(1.25).setDepth(8);
    const b = this.sprite.body as Phaser.Physics.Arcade.Body;
    b.setCircle(12).setBounce(1).setGravityY(-500);
    scene.physics.add.collider(this.sprite, scene.solids);
    scene.physics.add.collider(this.sprite, scene.crates);
  }
  hitbox() { const b = this.sprite.body as Phaser.Physics.Arcade.Body; return new Rect(b.x + 3, b.y + 3, b.width - 6, b.height - 6); }
  update(_time: number, dt: number) { this.sprite.angle += 220 * dt; }
  protected onDie() {}
}

/** Übungsscheibe fürs Tutorial: steht still und fällt beim ersten Hieb um. */
export class Target extends Enemy {
  readonly kind = '';
  private img: Phaser.GameObjects.Image;
  constructor(scene: GameScene, private x: number, private groundY: number) {
    super(scene);
    this.harmful = false; this.stompable = true; this.reward = 1;
    this.img = scene.add.image(x, groundY, 'target').setOrigin(0.5, 1).setDepth(8);
  }
  hitbox() { return new Rect(this.x - 22, this.groundY - 66, 44, 66); }
  update(time: number) { this.img.angle = Math.sin(time / 400) * 2; }
  protected onDie(dir: number) {
    this.scene.fx.burst(this.x, this.groundY - 40, 0xd23b3b, 10);
    this.scene.fx.burst(this.x, this.groundY - 40, 0xf4f4f4, 10);
    this.img.setOrigin(0.5, 1);
    this.scene.tweens.add({ targets: this.img, angle: (dir || 1) * 90, duration: 360, ease: 'Bounce.Out' });
    this.scene.tweens.add({ targets: this.img, alpha: 0, delay: 900, duration: 400, onComplete: () => this.img.destroy() });
  }
}
