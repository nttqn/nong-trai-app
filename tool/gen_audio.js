// Synthesises every sound effect into assets/audio/*.wav (16-bit mono).
// Run from the project root: node tool/gen_audio.js
const fs = require('fs');
const path = require('path');

const RATE = 22050;
const OUT = path.join(__dirname, '..', 'assets', 'audio');
fs.mkdirSync(OUT, { recursive: true });

// Deterministic noise so reruns give identical files.
let seed = 4242;
const noise = () => {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return seed / 0x3fffffff - 1;
};

function write(name, x, peak = 0.8) {
  // Short fade-out so nothing ends on a click.
  const fade = Math.min(x.length, Math.round(0.01 * RATE));
  for (let i = 0; i < fade; i++) x[x.length - 1 - i] *= i / fade;
  let max = 0;
  for (const s of x) max = Math.max(max, Math.abs(s));
  const gain = max > 0 ? peak / max : 1;
  const data = Buffer.alloc(x.length * 2);
  x.forEach((s, i) =>
    data.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(s * gain * 32767))), i * 2));
  const head = Buffer.alloc(44);
  head.write('RIFF', 0);
  head.writeUInt32LE(36 + data.length, 4);
  head.write('WAVEfmt ', 8);
  head.writeUInt32LE(16, 16);
  head.writeUInt16LE(1, 20);
  head.writeUInt16LE(1, 22);
  head.writeUInt32LE(RATE, 24);
  head.writeUInt32LE(RATE * 2, 28);
  head.writeUInt16LE(2, 32);
  head.writeUInt16LE(16, 34);
  head.write('data', 36);
  head.writeUInt32LE(data.length, 40);
  fs.writeFileSync(path.join(OUT, name + '.wav'), Buffer.concat([head, data]));
  console.log(name, (x.length / RATE).toFixed(2) + 's');
}

const buf = (seconds) => new Float64Array(Math.round(seconds * RATE));
const at = (t) => Math.round(t * RATE);

function lowpass(x, cutoff) {
  const a = 1 - Math.exp((-2 * Math.PI * cutoff) / RATE);
  let y = 0;
  for (let i = 0; i < x.length; i++) {
    y += a * (x[i] - y);
    x[i] = y;
  }
  return x;
}

function highpass(x, cutoff) {
  const lp = lowpass(Float64Array.from(x), cutoff);
  for (let i = 0; i < x.length; i++) x[i] -= lp[i];
  return x;
}

// RBJ biquad band-pass (constant peak gain); f may be a function of i.
function bandpass(x, f, q) {
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const fc = typeof f === 'function' ? f(i) : f;
    const w = 2 * Math.PI * fc / RATE, al = Math.sin(w) / (2 * q), c = Math.cos(w);
    const a0 = 1 + al;
    const y = (al * x[i] - al * x2 - (-2 * c) * y1 - (1 - al) * y2) / a0;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = y;
    x[i] = y;
  }
  return x;
}

// Sine (or other wave) sweeping f0 -> f1 with exponential decay.
function tone(x, start, dur, f0, f1, amp, decay = 6, wave = Math.sin) {
  const s0 = at(start), n = at(dur);
  let ph = 0;
  for (let i = 0; i < n && s0 + i < x.length; i++) {
    const k = i / n;
    ph += (2 * Math.PI * f0 * Math.pow(f1 / f0, k)) / RATE;
    const env = Math.min(1, i / (RATE * 0.004)) * Math.exp(-decay * k);
    x[s0 + i] += wave(ph) * amp * env;
  }
}

const saw = (p) => ((p / Math.PI) % 2) - 1;
const tri = (p) => 2 * Math.abs(saw(p)) - 1;

function noiseBurst(x, start, dur, amp, env) {
  const s0 = at(start), n = at(dur);
  for (let i = 0; i < n && s0 + i < x.length; i++) x[s0 + i] += noise() * amp * env(i / n);
}

// A plucked string (đàn tranh), Karplus-Strong.
function pluck(x, start, f, amp, dur = 1.2, damp = 0.995) {
  const n = Math.max(2, Math.round(RATE / f));
  const line = new Float64Array(n);
  for (let i = 0; i < n; i++) line[i] = noise();
  for (let i = 1; i < n; i++) line[i] = line[i] * 0.6 + line[i - 1] * 0.4;
  const s0 = at(start), len = at(dur);
  let idx = 0;
  for (let i = 0; i < len && s0 + i < x.length; i++) {
    const v = line[idx];
    line[idx] = damp * 0.5 * (v + line[(idx + 1) % n]);
    idx = (idx + 1) % n;
    x[s0 + i] += v * amp;
  }
}

// A voiced sound: sawtooth through a moving formant, with pitch contour
// pitch(k) and loudness env(k) over 0..1. Used for the animals.
function voice(x, start, dur, pitch, env, formants, { breath = 0.05, q = 4 } = {}) {
  const n = at(dur), src = new Float64Array(n);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const k = i / n;
    ph += (2 * Math.PI * pitch(k)) / RATE;
    src[i] = (saw(ph) + noise() * breath) * env(k);
  }
  const out = new Float64Array(n);
  for (const [f, g] of formants) {
    const b = bandpass(Float64Array.from(src), typeof f === 'function' ? (i) => f(i / n) : f, q);
    for (let i = 0; i < n; i++) out[i] += b[i] * g;
  }
  const s0 = at(start);
  for (let i = 0; i < n && s0 + i < x.length; i++) x[s0 + i] += out[i];
}

const ad = (a, d) => (k) => Math.min(1, k / a) * Math.min(1, (1 - k) / d);

// ---------------------------------------------------------------- UI

// Soft wooden tap (tre / mõ).
{
  const x = buf(0.09);
  tone(x, 0, 0.09, 1250, 1000, 0.8, 9);
  tone(x, 0, 0.05, 2600, 2300, 0.2, 12);
  write('tap', x, 0.55);
}

// Something refused: two low muted knocks.
{
  const x = buf(0.26);
  tone(x, 0, 0.11, 240, 200, 0.8, 7, tri);
  tone(x, 0.12, 0.13, 200, 160, 0.8, 7, tri);
  write('error', lowpass(x, 1400), 0.5);
}

// ---------------------------------------------------------------- field work

// Planting: a soft dig into soil and a tiny rising "sprout" blip.
{
  const x = buf(0.32);
  noiseBurst(x, 0, 0.14, 0.9, (k) => Math.exp(-6 * k));
  lowpass(x, 900);
  tone(x, 0.1, 0.18, 520, 900, 0.35, 5);
  write('plant', x, 0.6);
}

// Harvest: a rustle of stalks then a bright pop.
{
  const x = buf(0.5);
  const r = buf(0.5);
  noiseBurst(r, 0, 0.25, 1, (k) => Math.sin(Math.PI * k) * (0.6 + 0.4 * Math.sin(k * 60)));
  bandpass(r, 3200, 1.2);
  for (let i = 0; i < x.length; i++) x[i] += r[i] * 0.7;
  tone(x, 0.18, 0.12, 600, 1300, 0.7, 4);
  tone(x, 0.24, 0.25, 1568, 1568, 0.25, 6);
  write('harvest', x, 0.7);
}

// Picking fruit: a twig snap and a plump drop.
{
  const x = buf(0.4);
  noiseBurst(x, 0, 0.02, 1, (k) => 1 - k);
  highpass(x, 2000);
  tone(x, 0.08, 0.2, 380, 140, 0.9, 5);
  write('pick', x, 0.65);
}

// Scattering grain/feed.
{
  const x = buf(0.55);
  for (let k = 0; k < 45; k++) {
    const t = Math.pow(Math.abs(noise()), 0.7) * 0.45;
    noiseBurst(x, t, 0.006, 0.6 + 0.4 * noise(), (q) => 1 - q);
  }
  bandpass(x, 4200, 0.9);
  write('feed', x, 0.55);
}

// Manure/fertiliser sparkle: rising chime run.
{
  const x = buf(0.6);
  [1047, 1319, 1568, 2093].forEach((f, i) => tone(x, i * 0.07, 0.35, f, f, 0.4, 5));
  write('sparkle', x, 0.55);
}

// Water: splash for stocking and catching fish.
{
  const x = buf(0.6);
  const s = buf(0.6);
  noiseBurst(s, 0, 0.45, 1, (k) => Math.min(1, k * 25) * Math.exp(-5 * k));
  bandpass(s, (i) => 1800 - 1200 * (i / s.length), 0.8);
  for (let i = 0; i < x.length; i++) x[i] += s[i];
  // A few bubbles.
  for (const [t, f] of [[0.12, 700], [0.2, 950], [0.3, 820], [0.38, 1100]]) tone(x, t, 0.06, f, f * 1.8, 0.25, 4);
  write('splash', x, 0.65);
}

// ---------------------------------------------------------------- building

// Build: three hammer knocks on wood, last one with a little bell.
{
  const x = buf(0.75);
  for (const t of [0, 0.17, 0.34]) {
    tone(x, t, 0.1, 330, 210, 0.9, 8, tri);
    noiseBurst(x, t, 0.025, 0.5, (k) => 1 - k);
  }
  lowpass(x, 2500);
  tone(x, 0.36, 0.38, 1760, 1760, 0.18, 4);
  write('build', x, 0.7);
}

// Chop (clearing rocks, stumps, weeds): axe thunk + crumble.
{
  const x = buf(0.5);
  tone(x, 0, 0.14, 180, 90, 1, 6, tri);
  noiseBurst(x, 0, 0.04, 0.8, (k) => 1 - k);
  noiseBurst(x, 0.1, 0.35, 0.35, (k) => Math.exp(-4 * k) * (0.5 + 0.5 * Math.abs(Math.sin(k * 40))));
  write('chop', lowpass(x, 1800), 0.7);
}

// Remove: a soft downward whoosh.
{
  const x = buf(0.35);
  noiseBurst(x, 0, 0.35, 1, (k) => Math.sin(Math.PI * k));
  bandpass(x, (i) => 2500 - 2000 * (i / x.length), 1.5);
  write('remove', x, 0.5);
}

// Place / moved: wooden thud.
{
  const x = buf(0.18);
  tone(x, 0, 0.18, 220, 120, 1, 7);
  noiseBurst(x, 0, 0.02, 0.4, (k) => 1 - k);
  write('place', lowpass(x, 2000), 0.6);
}

// Workshop started: a millstone/press rumble with a clack.
{
  const x = buf(0.7);
  const r = buf(0.7);
  noiseBurst(r, 0, 0.6, 1, (k) => Math.sin(Math.PI * k) * (0.6 + 0.4 * Math.sin(k * 2 * Math.PI * 7)));
  lowpass(r, 300);
  for (let i = 0; i < x.length; i++) x[i] += r[i] * 1.4;
  tone(x, 0.05, 0.08, 900, 700, 0.5, 9);
  tone(x, 0.4, 0.08, 900, 700, 0.4, 9);
  write('work', x, 0.6);
}

// Goods collected: a cheerful two-note pop.
{
  const x = buf(0.35);
  tone(x, 0, 0.12, 700, 1050, 0.7, 4);
  tone(x, 0.09, 0.22, 1400, 1400, 0.35, 5);
  write('collect', x, 0.65);
}

// ---------------------------------------------------------------- money

// Coin: classic two-tone ding.
{
  const x = buf(0.5);
  tone(x, 0, 0.08, 1976, 1976, 0.5, 2, (p) => Math.sign(Math.sin(p)) * 0.5 + Math.sin(p) * 0.5);
  tone(x, 0.07, 0.42, 2637, 2637, 0.5, 6, (p) => Math.sign(Math.sin(p)) * 0.5 + Math.sin(p) * 0.5);
  write('coin', lowpass(x, 6000), 0.5);
}

// Order delivered: coins pouring + a đàn tranh flourish.
{
  const x = buf(1.1);
  for (let k = 0; k < 9; k++) {
    const f = 2200 + 900 * Math.abs(noise());
    tone(x, k * 0.045, 0.12, f, f, 0.18, 6);
  }
  [523, 659, 784, 1047].forEach((f, i) => pluck(x, 0.25 + i * 0.09, f, 0.5, 0.85));
  write('cash', x, 0.7);
}

// ---------------------------------------------------------------- milestones

// Quest done: three-note đàn tranh phrase (sol la đô).
{
  const x = buf(1.3);
  [784, 880, 1047].forEach((f, i) => pluck(x, i * 0.13, f, 0.7, 1.1));
  pluck(x, 0.42, 1568, 0.3, 0.9);
  write('quest', x, 0.7);
}

// Level up / house / new land: rising pentatonic run and a small gong.
{
  const x = buf(2.2);
  [523, 587, 698, 784, 880, 1047, 1175, 1397].forEach((f, i) => pluck(x, i * 0.075, f, 0.55, 1.2));
  const parts = [1, 1.48, 1.92, 2.56, 3.2];
  for (let p = 0; p < parts.length; p++) {
    const f = 196 * parts[p];
    const s0 = at(0.62);
    for (let i = 0; s0 + i < x.length; i++) {
      const tt = i / RATE;
      x[s0 + i] += Math.sin(2 * Math.PI * f * (1 + 0.004 * (1 - Math.exp(-tt * 3))) * tt) *
        (0.5 / (p + 1.3)) * Math.exp(-(1.4 + p) * tt) * Math.min(1, tt / 0.01);
    }
  }
  write('levelup', x, 0.75);
}

// ---------------------------------------------------------------- animals

// Chicken: "cục cục ta-tác".
{
  const x = buf(0.9);
  const cluck = (t, f, d) => voice(x, t, d, (k) => f * (1 + 0.5 * Math.sin(Math.PI * k)), ad(0.1, 0.4),
    [[(k) => 900 + 700 * k, 1], [2600, 0.4]], { q: 5, breath: 0.25 });
  cluck(0, 330, 0.07);
  cluck(0.13, 340, 0.07);
  cluck(0.32, 420, 0.06);
  voice(x, 0.42, 0.32, (k) => 520 + 260 * Math.sin(Math.PI * Math.min(1, k * 1.4)), ad(0.08, 0.5),
    [[1300, 1], [2900, 0.5]], { q: 4, breath: 0.3 });
  write('ga', x, 0.6);
}

// Duck: two nasal "quạc quạc".
{
  const x = buf(0.7);
  for (const t of [0, 0.3]) {
    voice(x, t, 0.22, (k) => 300 - 90 * k, ad(0.06, 0.5),
      [[(k) => 1300 - 300 * k, 1], [2400, 0.6], [600, 0.3]], { q: 6, breath: 0.15 });
  }
  write('vit', x, 0.6);
}

// Pig: grunty "ụt ịt".
{
  const x = buf(0.7);
  for (const [t, f, d] of [[0, 120, 0.18], [0.26, 150, 0.24]]) {
    voice(x, t, d, (k) => f * (1 - 0.25 * k) + 20 * Math.sin(k * 70), ad(0.1, 0.4),
      [[500, 1], [(k) => 1100 + 500 * k, 0.6]], { q: 3, breath: 0.5 });
  }
  write('lon', lowpass(x, 3000), 0.65);
}

// Cow: "ò ò" — the vowel opens from mmm to ooo.
{
  const x = buf(1.5);
  voice(x, 0, 1.4, (k) => 115 + 40 * Math.sin(Math.PI * Math.min(1, k * 1.3)) - 25 * k, ad(0.12, 0.35),
    [[(k) => 300 + 450 * Math.min(1, k * 3), 1], [(k) => 900 + 300 * Math.min(1, k * 3), 0.4]], { q: 3, breath: 0.08 });
  write('bo', lowpass(x, 2200), 0.7);
}

// Buffalo: lower, longer, rougher than the cow.
{
  const x = buf(1.8);
  voice(x, 0, 1.7, (k) => 78 + 25 * Math.sin(Math.PI * Math.min(1, k * 1.2)) + 4 * Math.sin(k * 140), ad(0.15, 0.3),
    [[(k) => 260 + 300 * Math.min(1, k * 2.5), 1], [750, 0.35]], { q: 2.5, breath: 0.15 });
  write('trau', lowpass(x, 1800), 0.75);
}

// Goat: a shaky "be-e-e", nasal, with a fast bleating tremolo.
{
  const x = buf(0.95);
  const shake = (k) => 0.55 + 0.45 * Math.abs(Math.sin(k * 0.9 * Math.PI * 14));
  voice(x, 0, 0.85, (k) => 330 + 50 * Math.sin(Math.PI * Math.min(1, k * 1.6)) - 60 * k + 18 * Math.sin(k * 90),
    (k) => ad(0.06, 0.35)(k) * shake(k),
    [[(k) => 700 + 250 * Math.min(1, k * 4), 1], [1900, 0.55], [2900, 0.25]], { q: 5, breath: 0.12 });
  write('de', lowpass(x, 4200), 0.6);
}

// Bees: a soft buzzing swarm passing by.
{
  const dur = 1.3, x = buf(dur);
  for (const [f, a, ph] of [[220, 1, 0], [233, 0.8, 1.3], [208, 0.7, 2.1], [440, 0.25, 0.5]]) {
    let p = 0;
    for (let i = 0; i < x.length; i++) {
      const k = i / x.length;
      p += (2 * Math.PI * (f + 6 * Math.sin(k * 23 + ph))) / RATE;
      const env = Math.sin(Math.PI * k) * (0.7 + 0.3 * Math.sin(k * 41 + ph));
      x[i] += saw(p) * a * env;
    }
  }
  write('ong', bandpass(x, 900, 1.2), 0.45);
}
