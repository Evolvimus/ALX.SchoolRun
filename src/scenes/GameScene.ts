import Phaser from 'phaser';
import { LEVELS, Level, countLeaves } from '../data/levels';
import { getCharacter, Character, hasAbility } from '../data/characters';
import { persist, save } from '../services/save';
import { sfx } from '../services/audio';
import { button, FONT, portraitKey } from './ui';
import { Controls, NO_CONTROLS, Player } from '../game/Player';
import { Fx } from '../game/fx';
import { Ball, Blower, Bookworm, Burner, Caterpillar, DustMouse, Enemy, Magnet, Plane } from '../game/enemies';
import { botControls } from '../game/bot';

const T = 45;
const BAR = 72; // schwarze Anzeige-Leiste oben
const FULL = '#KRL';
const Rect = Phaser.Geom.Rectangle;

interface Leaf { img: Phaser.GameObjects.Image; x: number; y: number; value: number; taken: boolean; }
interface Checkpoint { x: number; y: number; img: Phaser.GameObjects.Image; active: boolean; }

export class GameScene extends Phaser.Scene {
  player!: Player;
  fx!: Fx;
  solids!: Phaser.Physics.Arcade.StaticGroup;
  crates!: Phaser.Physics.Arcade.StaticGroup;
  enemies: Enemy[] = [];
  spikes: Phaser.Geom.Rectangle[] = [];

  private char!: Character;
  private level!: Level;
  private levelIndex = 0;
  private startCheckpoint = -1;
  private grid: string[] = [];
  private leaves: Leaf[] = [];
  private checkpoints: Checkpoint[] = [];
  private checkpointIndex = -1;
  private spawn = new Phaser.Math.Vector2();
  private goalX = 0;
  private treeGold!: Phaser.GameObjects.Image;
  private total = 0;
  private collected = 0;
  private bonus = 0;
  private combo = 0;
  private lastLeafAt = 0;
  private startTime = -1;
  private done = false;
  private smashQuoted = false;
  private bot = false;
  private panelX = 480;
  private bg!: Phaser.GameObjects.TileSprite;
  private hudLives: Phaser.GameObjects.Image[] = [];
  private hudLeaves!: Phaser.GameObjects.Text;
  private hudTime!: Phaser.GameObjects.Text;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private touch = { left: false, right: false, jump: false, attack: false };

  constructor() { super('Game'); }

  init(data: { level?: number; checkpoint?: number }) {
    this.levelIndex = Phaser.Math.Clamp(data.level ?? 0, 0, LEVELS.length - 1);
    this.startCheckpoint = data.checkpoint ?? -1;
  }

  // ------------------------------------------------------------------ Aufbau
  create() {
    this.enemies = []; this.spikes = []; this.leaves = []; this.checkpoints = [];
    this.collected = this.bonus = this.combo = 0;
    this.done = false; this.smashQuoted = false; this.startTime = -1; this.checkpointIndex = -1; this.panelX = 480;
    this.touch = { left: false, right: false, jump: false, attack: false };
    this.bot = new URLSearchParams(location.search).has('bot');
    this.char = getCharacter(save.selected);
    const level = this.level = LEVELS[this.levelIndex];
    this.grid = level.map;
    this.total = countLeaves(level);
    const W = this.grid[0].length * T, H = this.grid.length * T;

    this.physics.world.setBounds(0, 0, W, H + 400);
    this.physics.world.resume();
    this.cameras.main.setBounds(0, 0, W, H).setBackgroundColor('#0b0b0d');
    this.bg = this.add.tileSprite(480, 202.5, 960, 405, level.bg).setScrollFactor(0);
    this.fx = new Fx(this);
    this.solids = this.physics.add.staticGroup();
    this.crates = this.physics.add.staticGroup();
    const mats = this.physics.add.staticGroup();

    this.buildTerrain();
    this.buildObjects(mats);
    const touch = this.sys.game.device.input.touch;
    for (const [col, row, raw] of level.hints) {
      const named = this.char.weapon && this.char.weapon !== 'ruler' ? raw.replace('LINEAL-HIEB', 'HAMMER-SCHLAG') : raw;
      const text = touch ? named.replace('PFEILTASTEN', '< >').replace('LEERTASTE', '^') : named;
      this.add.text(col * T, row * T, text, { fontFamily: FONT, fontSize: '10px', color: '#ffffff', lineSpacing: 6, backgroundColor: '#0b0b0dcc', padding: { x: 8, y: 6 } })
        .setDepth(3);
    }

    // Start am Anfang oder (nach „Nachsitzen“) am letzten Setzling
    if (this.startCheckpoint >= 0 && this.checkpoints[this.startCheckpoint]) {
      for (let i = 0; i <= this.startCheckpoint; i++) this.checkpoints[i].img.setTexture('seed-1');
      for (let i = 0; i <= this.startCheckpoint; i++) this.checkpoints[i].active = true;
      const cp = this.checkpoints[this.startCheckpoint];
      this.spawn.set(cp.x, cp.y - 30);
      this.checkpointIndex = this.startCheckpoint;
    }
    this.player = new Player(this, this.spawn.x, this.spawn.y, this.char);

    this.physics.add.collider(this.player.zone, this.solids);
    this.physics.add.collider(this.player.zone, mats, () => { if (this.player.body.touching.down) this.player.bounce(-880); });
    this.physics.add.collider(this.player.zone, this.crates, (_p, c) => {
      if (!hasAbility(this.char, 'smash')) return;
      if (this.char.smashQuote && !this.smashQuoted) { this.smashQuoted = true; this.player.say(this.char.smashQuote, this.time.now); }
      const crate = c as Phaser.Physics.Arcade.Image;
      crate.disableBody();
      this.fx.burst(crate.x, crate.y, 0xb8834c, 12);
      sfx.hit();
      this.tweens.add({ targets: crate, alpha: 0, scale: 1.4, duration: 150, onComplete: () => crate.destroy() });
    });

    this.cameras.main.startFollow(this.player.zone, true, 0.14, 0.14, -90, 0);
    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys('W,A,D,SPACE,X,J,M,ESC') as Record<string, Phaser.Input.Keyboard.Key>;
    this.keys.ESC.on('down', () => this.scene.start('Levels'));
    this.keys.M.on('down', () => sfx.toggleMute());

    this.createHud();
    this.createTouchControls();
    (window as unknown as Record<string, unknown>).__alx = { level: this.levelIndex, result: null };
  }

  /** Zusammenhängende Kacheln einer Zeile werden zu einem Kollisionskörper – das verhindert Hängenbleiben an Kanten. */
  private buildTerrain() {
    const solid = (c0: number, c1: number, ry: number, thin: boolean) => {
      const w = (c1 - c0 + 1) * T;
      this.solids.add(this.add.zone(c0 * T + w / 2, thin ? ry * T + 9 : ry * T + T / 2, w, thin ? 18 : T));
    };
    const TILE: Record<string, string> = { K: 'box', R: 'shelf', L: 'lab' };
    this.grid.forEach((row, ry) => {
      let run = -1, thin = -1;
      for (let rx = 0; rx <= row.length; rx++) {
        const ch = row[rx] ?? ' ';
        const full = FULL.includes(ch);
        if (full && run < 0) run = rx;
        if (!full && run >= 0) { solid(run, rx - 1, ry, false); run = -1; }
        if (ch === '=' && thin < 0) thin = rx;
        if (ch !== '=' && thin >= 0) { solid(thin, rx - 1, ry, true); thin = -1; }
        const x = rx * T + T / 2, y = ry * T + T / 2;
        if (ch === '#') this.add.image(x, y, this.grid[ry - 1]?.[rx] === '#' ? 'under' : 'ground').setDepth(5);
        else if (TILE[ch]) this.add.image(x, y, TILE[ch]).setDepth(5);
        else if (ch === '=') this.add.image(x, y - 13, 'platform').setDepth(5);
      }
    });
  }

  private buildObjects(mats: Phaser.Physics.Arcade.StaticGroup) {
    const holes: { x: number; y: number; col: number }[] = [];
    let burners = 0;
    this.grid.forEach((row, ry) => [...row].forEach((ch, rx) => {
      const x = rx * T + T / 2, y = ry * T + T / 2, floor = (ry + 1) * T;
      switch (ch) {
        case 'M': mats.create(x, y + 15, 'mat').setDepth(5); break;
        case 'B': this.crates.create(x, y, 'crate').setDepth(5); break;
        case '^': this.add.image(x, y, 'spikes').setDepth(5); this.spikes.push(new Rect(x - 20, floor - 14, 40, 14)); break;
        case 'c': this.addLeaf(this.add.image(x, y, 'leaf').setDepth(6), x, y, 1); break;
        case 'S': this.checkpoints.push({ x, y: floor, img: this.add.image(x, floor, 'seed-0').setOrigin(0.5, 1).setDepth(6), active: false }); break;
        case 'F':
          this.goalX = x;
          this.add.image(x, floor, 'tree-bare').setOrigin(0.5, 1).setDepth(4);
          this.treeGold = this.add.image(x, floor, 'tree-gold').setOrigin(0.5, 1).setDepth(4).setAlpha(0);
          break;
        case 'P': this.spawn.set(x, y - 12); break;
        case 'm': this.enemies.push(new DustMouse(this, x, y + 6)); break;
        case 'e': for (let i = 0; i < 3; i++) this.enemies.push(new Plane(this, x, y, i)); break;
        case 'w': holes.push({ x, y: floor, col: rx }); break;
        case 'o': this.enemies.push(new Ball(this, x, y)); break;
        case '<': this.enemies.push(new Blower(this, x, floor, -1)); break;
        case '>': this.enemies.push(new Blower(this, x, floor, 1)); break;
        case 'N': this.enemies.push(new Magnet(this, x, y)); break;
        case 'f': this.enemies.push(new Burner(this, x, floor, burners++ * 1100)); break;
        case 'C': this.enemies.push(new Caterpillar(this, x, floor)); break;
      }
    }));
    // Benachbarte Löcher gehören zu einem Bücherwurm
    holes.sort((a, b) => a.col - b.col);
    let group: typeof holes = [];
    for (const h of holes) {
      if (group.length && h.col - group[group.length - 1].col > 14) { this.enemies.push(new Bookworm(this, group)); group = []; }
      group.push(h);
    }
    if (group.length) this.enemies.push(new Bookworm(this, group));
    this.checkpoints.sort((a, b) => a.x - b.x);
  }

  /** Ein einsammelbares Blatt (auch von der Raupe gerettete große Blätter). */
  addLeaf(img: Phaser.GameObjects.Image, x: number, y: number, value: number) {
    this.leaves.push({ img, x, y, value, taken: false });
    if (value === 1) {
      this.tweens.add({ targets: img, y: y - 5, duration: 900 + (x % 7) * 40, yoyo: true, repeat: -1, ease: 'Sine.InOut' });
      this.tweens.add({ targets: img, angle: { from: -9, to: 9 }, duration: 1300 + (x % 5) * 60, yoyo: true, repeat: -1, ease: 'Sine.InOut' });
    }
  }

  private createHud() {
    const fix = <O extends Phaser.GameObjects.Components.ScrollFactor & Phaser.GameObjects.Components.Depth>(o: O) => o.setScrollFactor(0).setDepth(20);
    fix(this.add.rectangle(480, BAR / 2, 960, BAR, 0x000000));
    fix(this.add.rectangle(480, BAR, 960, 3, 0x2c2c31));
    fix(this.add.circle(42, 36, 27, 0x1c1c22).setStrokeStyle(3, 0x6b4426));
    const face = fix(this.add.image(42, 46, portraitKey(this, this.char)));
    face.setScale(48 / face.height).setCrop(0, 0, face.width, face.height * 0.55);
    this.hudLives = [];
    for (let i = 0; i < 3; i++) this.hudLives.push(fix(this.add.image(102 + i * 40, 36, 'leaf-green')));
    fix(this.add.image(256, 36, 'leaf').setScale(0.85));
    this.hudLeaves = fix(this.add.text(278, 28, '', { fontFamily: FONT, fontSize: '16px', color: '#ffd23f' }));
    this.hudTime = fix(this.add.text(450, 28, '', { fontFamily: FONT, fontSize: '16px', color: '#ffffff' }));
    fix(this.add.text(944, 20, `${this.levelIndex + 1} · ${this.level.name}`, { fontFamily: FONT, fontSize: '11px', color: '#fff' }).setOrigin(1, 0));
    fix(this.add.text(944, 42, this.char.name, { fontFamily: FONT, fontSize: '10px', color: '#9a9aa8' }).setOrigin(1, 0));
  }

  private createTouchControls() {
    if (!this.sys.game.device.input.touch) return;
    const mk = (x: number, label: string, k: keyof typeof this.touch) => {
      const b = this.add.image(x, 478, 'touch').setScrollFactor(0).setInteractive().setDepth(30);
      this.add.text(x, 478, label, { fontFamily: FONT, fontSize: '20px', color: '#fff' }).setOrigin(0.5).setScrollFactor(0).setDepth(31);
      b.on('pointerdown', () => (this.touch[k] = true));
      b.on('pointerup', () => (this.touch[k] = false));
      b.on('pointerout', () => (this.touch[k] = false));
    };
    mk(70, '<', 'left'); mk(180, '>', 'right'); mk(770, 'X', 'attack'); mk(880, '^', 'jump');
  }

  // ------------------------------------------------------------------ Hilfen für Gegner und Bot
  solidAt(x: number, y: number) {
    const ch = this.grid[Math.floor(y / T)]?.[Math.floor(x / T)];
    return ch !== undefined && (FULL.includes(ch) || (ch === '=' && y % T < 20));
  }
  crateAt(x: number, y: number) {
    return (this.crates.getChildren() as Phaser.Physics.Arcade.Image[]).some(c => c.body?.enable && Math.abs(c.x - x) < 23 && Math.abs(c.y - y) < 23);
  }
  onScreen(x: number, margin = 100) { return Math.abs(x - this.cameras.main.midPoint.x) < 480 + margin; }

  enemyDefeated(x: number, y: number, reward: number) {
    this.bonus += reward;
    this.fx.text(x, y - 10, `+${reward}`);
    sfx.defeat();
    this.hitStop(60);
  }

  /** Kurzes Einfrieren bei Treffern – macht Schläge spürbar. */
  private hitStop(ms: number) {
    if (this.physics.world.isPaused) return;
    this.physics.world.pause();
    this.time.delayedCall(ms, () => { if (!this.done || this.player.lives > 0) this.physics.world.resume(); });
  }

  // ------------------------------------------------------------------ Spielschleife
  private controls(time: number): Controls {
    if (this.done) return NO_CONTROLS;
    if (this.bot) return botControls(this, time);
    const k = this.keys, cu = this.cursors, t = this.touch;
    return {
      left: cu.left.isDown || k.A.isDown || t.left,
      right: cu.right.isDown || k.D.isDown || t.right,
      jump: cu.up.isDown || k.W.isDown || k.SPACE.isDown || t.jump,
      attack: k.X.isDown || k.J.isDown || t.attack,
    };
  }

  update(time: number, delta: number) {
    const cam = this.cameras.main, p = this.player;
    this.bg.tilePositionX = cam.scrollX * 0.5;
    if (this.startTime < 0) this.startTime = time;
    const dt = Math.min(delta, 34) / 1000;
    const c = this.controls(time);

    p.windTarget = 0; p.force.set(0, 0);
    for (const e of this.enemies) if (e.alive) e.update(time, dt);
    p.update(time, delta, c);
    if (this.done) { p.stop(); return; }

    cam.followOffset.x = Phaser.Math.Linear(cam.followOffset.x, -p.facing * 90, 0.04);
    this.checkLeaves(time);
    this.checkCheckpoints();
    this.checkEnemies(time, c);
    const pr = p.rect();
    if (this.spikes.some(s => Rect.Overlaps(s, pr))) this.hurt(time, p.x + p.facing * 10);
    if (p.y > this.grid.length * T + 60) this.fall(time);
    if (p.x > this.goalX - 60 && p.onGround) this.finish(time);

    Object.assign((window as unknown as { __alx: object }).__alx, { x: Math.round(p.x), y: Math.round(p.y), lives: p.lives, fps: Math.round(this.game.loop.actualFps) });
    this.hudLeaves.setText(`${this.collected}/${this.total}`);
    this.hudTime.setText(`ZEIT ${((time - this.startTime) / 1000).toFixed(1)}`);
  }

  private checkLeaves(time: number) {
    const p = this.player;
    for (const l of this.leaves) {
      if (l.taken || Math.abs(l.x - p.x) > 30 || Math.abs(l.y - p.y) > 40) continue;
      l.taken = true;
      this.collected += l.value;
      this.combo = time - this.lastLeafAt < 700 ? this.combo + 1 : 0;
      this.lastLeafAt = time;
      sfx.leaf(this.combo);
      this.fx.burst(l.x, l.y, 0xffe98a, l.value > 1 ? 14 : 5);
      if (l.value > 1) this.fx.text(l.x, l.y - 20, `+${l.value}`);
      this.tweens.killTweensOf(l.img);
      this.tweens.add({ targets: l.img, y: l.img.y - 34, scale: 0.2, alpha: 0, angle: 200, duration: 260, onComplete: () => l.img.destroy() });
    }
  }

  private checkCheckpoints() {
    const p = this.player;
    this.checkpoints.forEach((cp, i) => {
      if (cp.active || Math.abs(cp.x - p.x) > 32 || Math.abs(cp.y - 30 - p.y) > 70) return;
      cp.active = true;
      this.checkpointIndex = Math.max(this.checkpointIndex, i);
      const best = this.checkpoints[this.checkpointIndex];
      this.spawn.set(best.x, best.y - 30);
      cp.img.setTexture('seed-1');
      this.tweens.add({ targets: cp.img, scaleX: { from: 0.6, to: 1 }, scaleY: { from: 1.5, to: 1 }, duration: 320, ease: 'Back.Out' });
      this.fx.leaves(cp.x, cp.y - 40, 8);
      this.fx.text(cp.x, cp.y - 78, 'Checkpoint!', '#a6e07a');
      sfx.checkpoint();
    });
  }

  private checkEnemies(time: number, c: Controls) {
    const p = this.player, pr = p.rect(), atk = p.attackRect(time);
    for (const e of this.enemies) {
      if (!e.alive) continue;
      const hb = e.hitbox();
      if (!hb) continue;
      if (atk && e.hittable && e.lastSwing !== p.swingId && Rect.Overlaps(atk, hb)) {
        e.lastSwing = p.swingId;
        this.fx.burst(hb.centerX, hb.centerY, 0xffffff, 6);
        this.cameras.main.shake(70, 0.004);
        e.hit(p.facing);
        continue;
      }
      if (!Rect.Overlaps(pr, hb)) continue;
      const fromAbove = p.body.velocity.y > 80 && p.body.bottom - hb.y < 26;
      if (fromAbove && e.bouncy) p.bounce(-760);
      else if (fromAbove && e.stompable) { e.stomp(); p.bounce(c.jump ? -620 : -430); }
      else if (e.harmful) this.hurt(time, hb.centerX);
    }
  }

  private loseLife() {
    const lost = this.hudLives[this.player.lives];
    if (lost) {
      lost.setTexture('leaf-wilt');
      this.tweens.add({ targets: lost, angle: 35, y: 42, duration: 300, ease: 'Bounce.Out' });
    }
    this.cameras.main.shake(180, 0.012);
    this.cameras.main.flash(120, 255, 80, 80);
    sfx.hurt();
    if (this.player.lives <= 0) this.gameOver();
  }

  private hurt(time: number, fromX: number) {
    if (this.done || !this.player.hurt(time, fromX)) return;
    this.fx.burst(this.player.x, this.player.y, 0xff5a5a, 10);
    this.loseLife();
  }

  /** Sturz in den Abgrund: ein Leben weg, zurück zum letzten Setzling. */
  private fall(time: number) {
    if (this.done) return;
    this.player.lives--;
    this.loseLife();
    if (this.player.lives > 0) this.player.respawn(time, this.spawn.x, this.spawn.y);
  }

  // ------------------------------------------------------------------ Levelende
  private panel(titleText: string, body: string) {
    const fix = (o: Phaser.GameObjects.Rectangle | Phaser.GameObjects.Text) => o.setScrollFactor(0).setDepth(40);
    const x = this.panelX;
    fix(this.add.rectangle(x, 290, 540, 330, 0x0b0b0d, 0.95).setStrokeStyle(4, 0xffcc33));
    fix(this.add.text(x, 170, titleText, { fontFamily: FONT, fontSize: '24px', color: '#ffcc33' }).setOrigin(0.5));
    fix(this.add.text(x, 270, body, { fontFamily: FONT, fontSize: '13px', color: '#fff', align: 'center', lineSpacing: 12 }).setOrigin(0.5));
  }
  private panelButtons(label: string, action: () => void) {
    button(this, this.panelX - 125, 395, label, action, 220).setScrollFactor(0).setDepth(41);
    button(this, this.panelX + 125, 395, 'Level', () => this.scene.start('Levels'), 220).setScrollFactor(0).setDepth(41);
  }
  private report(result: string) { (window as unknown as Record<string, unknown>).__alx = { level: this.levelIndex, result: this.bot && result === 'over' ? null : result, retries: this.registry.get('botRetries') ?? 0, lives: this.player.lives, leaves: this.collected, total: this.total }; }

  private gameOver() {
    this.done = true;
    this.physics.world.pause();
    sfx.over();
    this.report('over');
    this.panel('Nachsitzen!', 'Alle Leben verloren.\nEs geht am letzten Setzling weiter.');
    this.panelButtons('Nochmal', () => this.scene.restart({ level: this.levelIndex, checkpoint: this.checkpointIndex }));
    if (this.bot) {
      this.registry.inc('botRetries');
      this.time.delayedCall(800, () => this.scene.restart({ level: this.levelIndex, checkpoint: this.checkpointIndex }));
    }
  }

  /** Ziel erreicht: Die gesammelten Blätter fliegen in die Krone und der Ginkgo wird golden. */
  private finish(time: number) {
    this.done = true;
    const seconds = (time - this.startTime) / 1000;
    const cam = this.cameras.main;
    cam.stopFollow();
    cam.pan(this.goalX - 230, cam.midPoint.y, 500, 'Sine.easeInOut');
    this.panelX = 310;
    const n = Math.min(this.collected, 36);
    const share = this.total ? this.collected / this.total : 0;
    for (let i = 0; i < n; i++) {
      this.time.delayedCall(250 + i * 45, () => {
        const leaf = this.add.image(cam.scrollX + 256, cam.scrollY + 36, 'leaf-s').setDepth(18);
        const tx = this.goalX - 66 + Math.random() * 132, ty = 405 - 234 + 12 + Math.random() * 84;
        this.tweens.add({ targets: leaf, x: tx, duration: 620, ease: 'Sine.InOut' });
        this.tweens.add({ targets: leaf, y: ty, angle: 360, duration: 620, ease: 'Back.In', onComplete: () => {
          sfx.leaf(i % 14);
          this.treeGold.setAlpha(Math.min(1, ((i + 1) / n) * share * 1.15));
          this.fx.burst(tx, ty, 0xffe98a, 2);
          leaf.destroy();
        } });
      });
    }
    this.time.delayedCall(450 + n * 45 + 650, () => this.showResult(seconds));
  }

  private showResult(seconds: number) {
    const all = this.collected >= this.total;
    if (all) this.fx.leaves(this.goalX, 230, 30);
    sfx.win();
    const reward = this.collected + this.bonus + this.player.lives * 5;
    const id = this.level.id;
    const fromCheckpoint = this.startCheckpoint >= 0; // nach „Nachsitzen“ zählt die Zeit nicht als Bestzeit
    const best = save.bestTimes[id];
    const newBest = !fromCheckpoint && (!best || seconds < best);
    if (newBest) save.bestTimes[id] = seconds;
    save.bestLeaves[id] = Math.max(save.bestLeaves[id] ?? 0, this.collected);
    save.progress = Math.max(save.progress, Math.min(this.levelIndex + 1, LEVELS.length - 1));
    save.coins += reward;
    persist();
    this.report('win');
    this.panel(all ? 'Der Ginkgo leuchtet!' : 'Geschafft!', [
      `Blätter: ${this.collected}/${this.total}${all ? '  ALLE!' : ''}`,
      fromCheckpoint ? `Zeit: ${seconds.toFixed(1)}s (ab Setzling)` : `Zeit: ${seconds.toFixed(1)}s${newBest ? '  BESTZEIT!' : ''}`,
      `+${reward} Ginkgo-Taler`,
    ].join('\n'));
    const next = this.levelIndex + 1 < LEVELS.length;
    this.panelButtons(next ? 'Weiter' : 'Nochmal', () => this.scene.restart({ level: next ? this.levelIndex + 1 : this.levelIndex }));
  }
}
