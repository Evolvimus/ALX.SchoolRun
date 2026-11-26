import Phaser from 'phaser';
import { backButton, button, card, FONT, title, menuBackground } from './ui';
import { validateCode } from '../services/codeFormat';
import { redeemCode } from '../services/backend';
import { unlock } from '../services/save';
import { getCharacter } from '../data/characters';

export class RedeemScene extends Phaser.Scene {
  private codeEl!: HTMLInputElement;
  private busy = false;
  constructor() { super('Redeem'); }

  create() {
    menuBackground(this);
    title(this, 'Karten-Code einlösen');
    this.add.text(480, 110, 'Den Code findest du auf der Rückseite deiner ALX-Sammelkarte.\nJeder Code funktioniert nur ein einziges Mal!',
      { fontFamily: FONT, fontSize: '11px', color: '#fff', align: 'center' }).setOrigin(0.5);
    const msg = this.add.text(480, 315, '', { fontFamily: FONT, fontSize: '12px', color: '#fff', align: 'center' }).setOrigin(0.5);

    this.codeEl = document.getElementById('code-input') as HTMLInputElement;
    this.codeEl.value = '';
    this.codeEl.style.display = 'block';
    const place = () => {
      const r = this.game.canvas.getBoundingClientRect(), s = r.width / 960;
      this.codeEl.style.left = `${r.left + 480 * s - this.codeEl.offsetWidth / 2}px`;
      this.codeEl.style.top = `${r.top + 180 * s}px`;
    };
    place(); this.scale.on('resize', place);
    this.events.once('shutdown', () => { this.codeEl.style.display = 'none'; this.scale.off('resize', place); });

    const submit = async () => {
      if (this.busy) return;
      const code = validateCode(this.codeEl.value);
      if (!code) { msg.setColor('#ff7777').setText('Ungültiger Code – bitte nochmal genau abtippen.'); return; }
      this.busy = true; msg.setColor('#fff').setText('Wird geprüft …');
      const res = await redeemCode(code);
      this.busy = false;
      if (!res.ok) {
        msg.setColor('#ff7777').setText(res.reason === 'used' ? 'Dieser Code wurde schon eingelöst.'
          : res.reason === 'invalid' ? 'Diesen Code gibt es nicht.' : 'Keine Verbindung – versuche es später nochmal.');
        return;
      }
      unlock(res.characterId);
      this.codeEl.value = '';
      this.reveal(res.characterId, msg);
    };
    this.codeEl.onkeydown = e => { if (e.key === 'Enter') submit(); };
    button(this, 480, 262, 'Einlösen', submit, 200);
    backButton(this);
  }

  private reveal(id: string, msg: Phaser.GameObjects.Text) {
    const c = getCharacter(id);
    if (c.rarity === 'mythisch') msg.setColor('#ff7fbf').setText(`✨ MYTHISCH! ${c.name} freigeschaltet! ✨`);
    else msg.setColor('#7dff7d').setText(`🎉 ${c.name} freigeschaltet!`);
    const k = card(this, 480, 425, c, true, 0.1);
    this.tweens.add({ targets: k, scale: 1, angle: 360, duration: 700, ease: 'Back.Out' });
  }
}
