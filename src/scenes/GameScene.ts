import Phaser from 'phaser';
import { LEVELS, Level } from '../data/levels';
import { getCharacter, Character } from '../data/characters';
import { persist, save } from '../services/save';
import { button, FONT, portraitKey } from './ui';

const T = 45;
const BAR = 72;      // schwarze Anzeige-Leiste oben
const MAX_LIVES = 3;

export class GameScene extends Phaser.Scene {
  private player!: Phaser.Physics.Arcade.Sprite;
  private char!: Character;
  private level!: Level;
  private levelIndex = 0;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private touch = { left: false, right: false, jump: false };
  private jumpWasDown = false;
  private airJumps = 0;
  private coins = 0;
  private lives = MAX_LIVES;
  private hearts: Phaser.GameObjects.Image[] = [];
  private safeUntil = 0;
  private startTime = 0;
  private done = false;
  private hud!: Phaser.GameObjects.Text;
  private start = new Phaser.Math.Vector2();
  private bg!: Phaser.GameObjects.TileSprite;

  constructor() { super('Game'); }

  init(data: { level?: number }) {
    this.levelIndex = Phaser.Math.Clamp(data.level ?? 0, 0, LEVELS.length - 1);
  }

  create() {
    this.done = false; this.coins = 0; this.lives = MAX_LIVES; this.safeUntil = 0;
    this.touch = { left: false, right: false, jump: false };
    this.char = getCharacter(save.selected);
    const level = this.level = LEVELS[this.levelIndex];
    const W = level.map[0].length * T, H = level.map.length * T;
    this.physics.world.setBounds(0, 0, W, H + 200);
    this.cameras.main.setBounds(0, 0, W, H).setBackgroundColor('#0b0b0d');
    this.bg = this.add.tileSprite(480, 202.5, 960, 405, level.bg).setScrollFactor(0);

    const solids = this.physics.add.staticGroup();
    const crates = this.physics.add.staticGroup();
    const mats = this.physics.add.staticGroup();
    const coins = this.physics.add.staticGroup();
    const hazards = this.physics.add.staticGroup();
    const enemies = this.physics.add.group({ allowGravity: false });
    const balls = this.physics.add.group();
    let goal!: Phaser.Physics.Arcade.Image;

    level.map.forEach((row, ry) => [...row].forEach((ch, rx) => {
      const x = rx * T + T / 2, y = ry * T + T / 2;
      switch (ch) {
        case '#': solids.create(x, y, level.map[ry - 1]?.[rx] === '#' ? 'under' : 'ground'); break;
        case '=': solids.create(x, y - 13, 'platform'); break;
        case 'K': solids.create(x, y, 'box'); break;
        case 'M': mats.create(x, y + 15, 'mat'); break;
        case 'B': crates.create(x, y, 'crate'); break;
        case 'c': coins.create(x, y, 'coin'); break;
        case '^': hazards.create(x, y, 'spikes').setSize(42, 15).setOffset(1, 30); break;
        case 'e': {
          const e = enemies.create(x, y, 'plane') as Phaser.Physics.Arcade.Image;
          this.tweens.add({ targets: e, x: x - 180, duration: 2200, yoyo: true, repeat: -1, ease: 'Sine.InOut',
            onYoyo: () => e.setFlipX(true), onRepeat: () => e.setFlipX(false) });
          break;
        }
        case 'o': {
          const b = balls.create(x, y, 'ball') as Phaser.Physics.Arcade.Image;
          b.setScale(1.25).setBounce(1).setCircle(12);
          (b.body as Phaser.Physics.Arcade.Body).setGravityY(-500);
          break;
        }
        case 'P': this.start.set(x, y - 12); break;
        case 'F': goal = this.physics.add.staticImage(x, y + T * 2, 'flag'); break;
      }
    }));

    this.player = this.physics.add.sprite(this.start.x, this.start.y, portraitKey(this, this.char));
    this.player.setScale(60 / this.player.height);
    this.player.body!.setSize(this.player.width * 0.7, this.player.height * 0.95);
    this.player.setMaxVelocity(this.char.ability === 'speed' ? 420 : 320, 1000);

    this.physics.add.collider(this.player, solids);
    this.physics.add.collider(balls, solids);
    this.physics.add.collider(balls, crates);
    this.physics.add.collider(this.player, mats, () => {
      const body = this.player.body as Phaser.Physics.Arcade.Body;
      if (body.touching.down) body.setVelocityY(-880);          // Matte federt
    });
    this.physics.add.collider(this.player, crates, (_p, c) => {
      if (this.char.ability === 'smash') {
        const crate = c as Phaser.Physics.Arcade.Image;
        crate.disableBody();
        this.tweens.add({ targets: crate, alpha: 0, scale: 1.4, duration: 150, onComplete: () => crate.destroy() });
      }
    });
    this.physics.add.overlap(this.player, coins, (_p, c) => { (c as Phaser.Physics.Arcade.Image).destroy(); this.coins++; });
    this.physics.add.overlap(this.player, hazards, () => this.hurt());
    this.physics.add.overlap(this.player, enemies, () => this.hurt());
    this.physics.add.overlap(this.player, balls, () => this.hurt());
    this.physics.add.overlap(this.player, goal, () => this.finish());

    this.cameras.main.startFollow(this.player, true, 0.12, 0.12, -150, 0);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys('W,A,D,SPACE,ESC') as Record<string, Phaser.Input.Keyboard.Key>;
    this.keys.ESC.on('down', () => this.scene.start('Menu'));

    this.createHud();
    this.createTouchControls();
    this.startTime = -1;
  }

  private createHud() {
    const fix = <O extends Phaser.GameObjects.Components.ScrollFactor & Phaser.GameObjects.Components.Depth>(o: O) => o.setScrollFactor(0).setDepth(20);
    fix(this.add.rectangle(480, BAR / 2, 960, BAR, 0x000000));
    fix(this.add.rectangle(480, BAR, 960, 3, 0x2c2c31));
    fix(this.add.circle(42, 36, 27, 0x1c1c22).setStrokeStyle(3, 0x6b4426));           // Porträt
    const face = fix(this.add.image(42, 46, portraitKey(this, this.char)));
    face.setScale(48 / face.height).setCrop(0, 0, face.width, face.height * 0.55);
    this.hearts = [];
    for (let i = 0; i < MAX_LIVES; i++) this.hearts.push(fix(this.add.image(100 + i * 44, 36, 'heart').setScale(1.6)));
    this.hud = fix(this.add.text(250, 27, '', { fontFamily: FONT, fontSize: '16px', color: '#ffd23f' }));
    fix(this.add.text(944, 20, this.level.name, { fontFamily: FONT, fontSize: '11px', color: '#fff' }).setOrigin(1, 0));
    fix(this.add.text(944, 42, this.char.name, { fontFamily: FONT, fontSize: '10px', color: '#9a9aa8' }).setOrigin(1, 0));
  }

  private createTouchControls() {
    if (!this.sys.game.device.input.touch) return;
    const mk = (x: number, y: number, label: string, k: keyof typeof this.touch) => {
      const b = this.add.image(x, y, 'touch').setScrollFactor(0).setInteractive().setDepth(30);
      this.add.text(x, y, label, { fontFamily: FONT, fontSize: '22px', color: '#fff' }).setOrigin(0.5).setScrollFactor(0).setDepth(31);
      b.on('pointerdown', () => (this.touch[k] = true));
      b.on('pointerup', () => (this.touch[k] = false));
      b.on('pointerout', () => (this.touch[k] = false));
    };
    mk(70, 478, '<', 'left'); mk(180, 478, '>', 'right'); mk(880, 478, '^', 'jump');
  }

  update() {
    this.bg.tilePositionX = this.cameras.main.scrollX * 0.5;
    if (this.startTime < 0) this.startTime = this.time.now;
    if (this.done) return;
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    const left = this.cursors.left.isDown || this.keys.A.isDown || this.touch.left;
    const right = this.cursors.right.isDown || this.keys.D.isDown || this.touch.right;
    const jump = this.cursors.up.isDown || this.keys.W.isDown || this.keys.SPACE.isDown || this.touch.jump;
    const onGround = body.blocked.down || body.touching.down;
    const speed = this.char.ability === 'speed' ? 420 : 300;

    if (left) { body.setVelocityX(-speed); this.player.setFlipX(true); }
    else if (right) { body.setVelocityX(speed); this.player.setFlipX(false); }
    else body.setVelocityX(body.velocity.x * 0.75);

    if (onGround) this.airJumps = this.char.ability === 'doubleJump' ? 1 : 0;
    const pressed = jump && !this.jumpWasDown;
    const jumpV = this.char.ability === 'highJump' ? -780 : -640;
    if (pressed && onGround) body.setVelocityY(jumpV);
    else if (pressed && this.airJumps > 0) { this.airJumps--; body.setVelocityY(jumpV * 0.9); }
    if (this.char.ability === 'glide' && jump && body.velocity.y > 120) body.setVelocityY(120);
    this.jumpWasDown = jump;

    this.player.setAlpha(this.time.now < this.safeUntil && Math.floor(this.time.now / 80) % 2 ? 0.3 : 1);
    if (this.player.y > this.physics.world.bounds.height - 150) this.hurt(true);
    const t = ((this.time.now - this.startTime) / 1000).toFixed(1);
    this.hud.setText(`TALER ${this.coins}   ZEIT ${t}`);
  }

  /** Ein Leben verlieren. Bei einem Sturz geht es zurück zum Start. */
  private hurt(fell = false) {
    if (this.done || this.time.now < (fell ? this.safeUntil - 1200 : this.safeUntil)) return;
    this.lives--;
    this.hearts.forEach((h, i) => h.setAlpha(i < this.lives ? 1 : 0.15));
    this.cameras.main.shake(200, 0.01);
    if (this.lives <= 0) { this.gameOver(); return; }
    this.safeUntil = this.time.now + 1500;
    if (fell) (this.player.body as Phaser.Physics.Arcade.Body).reset(this.start.x, this.start.y);
    else this.player.setVelocityY(-400);
  }

  private panel(titleText: string, body: string) {
    this.done = true;
    this.physics.pause();
    const fix = (o: Phaser.GameObjects.Rectangle | Phaser.GameObjects.Text) => o.setScrollFactor(0).setDepth(40);
    fix(this.add.rectangle(480, 280, 560, 300, 0x0b0b0d, 0.95).setStrokeStyle(4, 0xffcc33));
    fix(this.add.text(480, 185, titleText, { fontFamily: FONT, fontSize: '26px', color: '#ffcc33' }).setOrigin(0.5));
    fix(this.add.text(480, 265, body, { fontFamily: FONT, fontSize: '14px', color: '#fff', align: 'center', lineSpacing: 10 }).setOrigin(0.5));
  }

  private gameOver() {
    this.panel('Nachsitzen!', 'Alle Leben verloren.\nVersuch es gleich nochmal.');
    button(this, 350, 365, 'Nochmal', () => this.scene.restart({ level: this.levelIndex }), 220).setScrollFactor(0).setDepth(41);
    button(this, 610, 365, 'Menü', () => this.scene.start('Menu'), 220).setScrollFactor(0).setDepth(41);
  }

  private finish() {
    if (this.done) return;
    const time = (this.time.now - this.startTime) / 1000;
    const reward = this.coins + 20 + this.lives * 5;
    save.coins += reward;
    const best = save.bestTimes[this.level.id];
    const newBest = !best || time < best;
    if (newBest) save.bestTimes[this.level.id] = time;
    persist();
    this.panel('Geschafft!', `Zeit: ${time.toFixed(1)}s${newBest ? ' (Bestzeit!)' : ''}\n+${reward} ALX-Taler`);
    const next = this.levelIndex + 1 < LEVELS.length;
    button(this, 350, 365, next ? 'Weiter' : 'Nochmal', () => this.scene.restart({ level: next ? this.levelIndex + 1 : this.levelIndex }), 220)
      .setScrollFactor(0).setDepth(41);
    button(this, 610, 365, 'Menü', () => this.scene.start('Menu'), 220).setScrollFactor(0).setDepth(41);
  }
}
