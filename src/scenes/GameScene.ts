import Phaser from 'phaser';
import { LEVELS } from '../data/levels';
import { getCharacter, Character } from '../data/characters';
import { persist, save } from '../services/save';
import { button, FONT, portraitKey } from './ui';

const T = 45;

export class GameScene extends Phaser.Scene {
  private player!: Phaser.Physics.Arcade.Sprite;
  private char!: Character;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private touch = { left: false, right: false, jump: false };
  private jumpWasDown = false;
  private airJumps = 0;
  private coins = 0;
  private startTime = 0;
  private done = false;
  private hud!: Phaser.GameObjects.Text;
  private start = new Phaser.Math.Vector2();
  private bg!: Phaser.GameObjects.TileSprite;

  constructor() { super('Game'); }

  create() {
    this.done = false; this.coins = 0; this.touch = { left: false, right: false, jump: false };
    this.char = getCharacter(save.selected);
    const level = LEVELS[0];
    const W = level.map[0].length * T, H = level.map.length * T;
    this.physics.world.setBounds(0, 0, W, H + 200);
    this.cameras.main.setBounds(0, 0, W, H).setBackgroundColor('#1a0f08');
    this.bg = this.add.tileSprite(480, 202.5, 960, 405, 'bg-school').setScrollFactor(0); // Klassenzimmer/Flur

    const solids = this.physics.add.staticGroup();
    const crates = this.physics.add.staticGroup();
    const coins = this.physics.add.staticGroup();
    const hazards = this.physics.add.staticGroup();
    const enemies = this.physics.add.group({ allowGravity: false });
    let goal!: Phaser.Physics.Arcade.Image;

    level.map.forEach((row, ry) => [...row].forEach((ch, rx) => {
      const x = rx * T + T / 2, y = ry * T + T / 2;
      switch (ch) {
        case '#': solids.create(x, y, 'ground'); break;
        case '=': solids.create(x, y - 13, 'platform'); break;
        case 'B': crates.create(x, y, 'crate'); break;
        case 'c': coins.create(x, y, 'coin'); break;
        case '^': hazards.create(x, y, 'spikes').setSize(42, 15).setOffset(1, 30); break;
        case 'e': {
          const e = enemies.create(x, y, 'plane') as Phaser.Physics.Arcade.Image;
          this.tweens.add({ targets: e, x: x - 180, duration: 2200, yoyo: true, repeat: -1, ease: 'Sine.InOut',
            onYoyo: () => e.setFlipX(true), onRepeat: () => e.setFlipX(false) });
          break;
        }
        case 'P': this.start.set(x, y); break;
        case 'F': goal = this.physics.add.staticImage(x, y + T * 2 - 22, 'flag'); break;
      }
    }));

    const key = portraitKey(this, this.char);
    this.player = this.physics.add.sprite(this.start.x, this.start.y, key);
    const s = 60 / this.player.height; this.player.setScale(s);
    this.player.body!.setSize(this.player.width * 0.7, this.player.height * 0.95);
    this.player.setCollideWorldBounds(false).setMaxVelocity(this.char.ability === 'speed' ? 420 : 320, 900);

    this.physics.add.collider(this.player, solids);
    this.physics.add.collider(this.player, crates, (_p, c) => {
      if (this.char.ability === 'smash') {
        const crate = c as Phaser.Physics.Arcade.Image;
        this.tweens.add({ targets: crate, alpha: 0, scale: 1.4, duration: 150, onComplete: () => crate.destroy() });
        crate.disableBody();
      }
    });
    this.physics.add.overlap(this.player, coins, (_p, c) => {
      (c as Phaser.Physics.Arcade.Image).destroy(); this.coins++; this.updateHud();
    });
    this.physics.add.overlap(this.player, hazards, () => this.die());
    this.physics.add.overlap(this.player, enemies, () => this.die());
    this.physics.add.overlap(this.player, goal, () => this.finish());

    this.cameras.main.startFollow(this.player, true, 0.12, 0.12, -150, 0);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys('W,A,D,SPACE,ESC') as Record<string, Phaser.Input.Keyboard.Key>;
    this.keys.ESC.on('down', () => this.scene.start('Menu'));

    this.hud = this.add.text(16, 12, '', { fontFamily: FONT, fontSize: '14px', color: '#fff' }).setScrollFactor(0).setStroke('#000', 4);
    this.add.text(944, 12, `${level.name} · ${this.char.name}`, { fontFamily: FONT, fontSize: '11px', color: '#fff' })
      .setOrigin(1, 0).setScrollFactor(0).setStroke('#000', 4);
    this.createTouchControls();
    this.startTime = this.time.now;
    this.updateHud();
  }

  private createTouchControls() {
    if (!this.sys.game.device.input.touch) return;
    const mk = (x: number, y: number, label: string, k: keyof typeof this.touch) => {
      const b = this.add.image(x, y, 'touch').setScrollFactor(0).setInteractive().setDepth(10);
      this.add.text(x, y, label, { fontFamily: FONT, fontSize: '21px', color: '#fff' }).setOrigin(0.5).setScrollFactor(0).setDepth(11);
      b.on('pointerdown', () => (this.touch[k] = true));
      b.on('pointerup', () => (this.touch[k] = false));
      b.on('pointerout', () => (this.touch[k] = false));
    };
    mk(70, 470, '◀', 'left'); mk(180, 470, '▶', 'right'); mk(880, 470, '⤒', 'jump');
  }

  private updateHud() {
    const t = ((this.time.now - this.startTime) / 1000).toFixed(1);
    this.hud.setText(`🪙 ${this.coins}   ⏱ ${t}s`);
  }

  update() {
    this.bg.tilePositionX = this.cameras.main.scrollX * 0.5;
    if (this.done) return;
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    const left = this.cursors.left.isDown || this.keys.A.isDown || this.touch.left;
    const right = this.cursors.right.isDown || this.keys.D.isDown || this.touch.right;
    const jump = this.cursors.up.isDown || this.keys.W.isDown || this.keys.SPACE.isDown || this.touch.jump;
    const onGround = body.blocked.down || body.touching.down;
    const speed = this.char.ability === 'speed' ? 420 : 300;

    body.setAccelerationX(0);
    if (left) { body.setVelocityX(-speed); this.player.setFlipX(true); }
    else if (right) { body.setVelocityX(speed); this.player.setFlipX(false); }
    else body.setVelocityX(body.velocity.x * 0.75);

    if (onGround) this.airJumps = this.char.ability === 'doubleJump' ? 1 : 0;
    const pressed = jump && !this.jumpWasDown;
    const jumpV = this.char.ability === 'highJump' ? -780 : -640;
    if (pressed && onGround) body.setVelocityY(jumpV);
    else if (pressed && this.airJumps > 0) { this.airJumps--; body.setVelocityY(jumpV * 0.9); }
    if (!jump && body.velocity.y < -200) body.setVelocityY(-200); // kurzer Tipp = kleiner Sprung
    if (this.char.ability === 'glide' && jump && body.velocity.y > 120) body.setVelocityY(120);
    this.jumpWasDown = jump;

    if (this.player.y > this.physics.world.bounds.height - 150) this.die();
    this.updateHud();
  }

  private die() {
    if (this.done) return;
    this.cameras.main.shake(200, 0.01);
    this.player.setPosition(this.start.x, this.start.y).setVelocity(0, 0);
  }

  private finish() {
    if (this.done) return;
    this.done = true;
    this.physics.pause();
    const time = (this.time.now - this.startTime) / 1000;
    const reward = this.coins + 20;
    save.coins += reward;
    const id = LEVELS[0].id;
    const best = save.bestTimes[id];
    const newBest = !best || time < best;
    if (newBest) save.bestTimes[id] = time;
    persist();
    this.add.rectangle(480, 270, 520, 300, 0x1b1f3b, 0.92).setScrollFactor(0).setStrokeStyle(4, 0xffcc33);
    this.add.text(480, 175, '🎓 Geschafft!', { fontFamily: FONT, fontSize: '25px', color: '#ffcc33' }).setOrigin(0.5).setScrollFactor(0);
    this.add.text(480, 250, `Zeit: ${time.toFixed(1)}s${newBest ? '  (Bestzeit!)' : ''}\n+${reward} ALX-Taler`,
      { fontFamily: FONT, fontSize: '15px', color: '#fff', align: 'center' }).setOrigin(0.5).setScrollFactor(0);
    button(this, 360, 350, 'Nochmal', () => this.scene.restart(), 200).setScrollFactor(0);
    button(this, 600, 350, 'Menü', () => this.scene.start('Menu'), 200).setScrollFactor(0);
  }
}
