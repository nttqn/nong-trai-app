// Composes the background music: two Vietnamese-countryside loops played
// by synthesised folk instruments — sáo trúc (bamboo flute), đàn bầu
// (monochord with its bending harmonic tone), đàn tranh (plucked zither),
// mõ and song lang, with birds by day and crickets by evening. Each track
// is a seamless loop: the reverb tail of the last bar folds onto the start.
//
// node tool/gen_music.js [onlyName]        -> build/music/*.wav
// FFMPEG=<ffmpeg with libvorbis> node tool/encode_music.js -> assets/audio/music
const fs = require('fs');
const path = require('path');

const RATE = 32000;
const OUT = path.join(__dirname, '..', 'build', 'music');
fs.mkdirSync(OUT, { recursive: true });

// ---------------------------------------------------------------- basics

let seed = 777;
const rnd = () => {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return seed / 0x7fffffff;
};
const noise = () => rnd() * 2 - 1;
const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);

class Mix {
  constructor(seconds) {
    this.n = Math.ceil(seconds * RATE);
    this.L = new Float64Array(this.n);
    this.R = new Float64Array(this.n);
    // Reverb send, mono.
    this.S = new Float64Array(this.n);
  }
  add(i, v, pan = 0, send = 0.3) {
    if (i < 0 || i >= this.n) return;
    const l = Math.cos((pan + 1) * Math.PI / 4), r = Math.sin((pan + 1) * Math.PI / 4);
    this.L[i] += v * l;
    this.R[i] += v * r;
    this.S[i] += v * send;
  }
}

// Pentatonic modes as semitone steps from the tonic.
const MODES = {
  gong: [0, 2, 4, 7, 9], // major pentatonic
  shang: [0, 2, 5, 7, 10],
  zhi: [0, 2, 5, 7, 9],
  yu: [0, 3, 5, 7, 10], // minor pentatonic
  dark: [0, 1, 5, 7, 8], // Japanese-like in-scale, for the demon fortress
};

function degreeToMidi(root, mode, d) {
  const steps = MODES[mode];
  const o = Math.floor(d / 5);
  const k = ((d % 5) + 5) % 5;
  return root + 12 * o + steps[k];
}

// "4:1.5 5:.5 r:1 7:2" -> [{d, beats}]; "r" is a rest.
function parse(line) {
  return line.trim().split(/\s+/).filter(Boolean).filter((t) => t !== '|').map((t) => {
    const [d, b] = t.split(':');
    return { d: d === 'r' ? null : parseFloat(d), beats: parseFloat(b) };
  });
}

// ---------------------------------------------------------------- instruments

// Karplus-Strong plucked string (guzheng / pipa).
function pluck(mix, t, midi, amp, { dur = 2.2, pan = 0, bright = 0.6, damp = 0.996, send = 0.35 } = {}) {
  const f = mtof(midi);
  const n = Math.max(2, Math.round(RATE / f));
  const line = new Float64Array(n);
  for (let i = 0; i < n; i++) line[i] = noise() * (0.4 + bright * 0.6);
  // Soften the excitation a bit for a rounder tone.
  for (let i = 1; i < n; i++) line[i] = line[i] * 0.7 + line[i - 1] * 0.3;
  const s0 = Math.round(t * RATE), len = Math.round(dur * RATE);
  let idx = 0;
  for (let i = 0; i < len; i++) {
    const v = line[idx];
    line[idx] = damp * 0.5 * (v + line[(idx + 1) % n]);
    idx = (idx + 1) % n;
    const env = Math.min(1, i / 40) * (i > len - 400 ? (len - i) / 400 : 1);
    mix.add(s0 + i, v * amp * env, pan, send);
  }
}

// Erhu: bowed, nasal, with delayed vibrato and a slide from the last note.
const erhuState = { midi: null };
function erhu(mix, t, midi, beats, spb, amp, { pan = 0.1, send = 0.4, slideFrom = null } = {}) {
  const dur = beats * spb;
  const s0 = Math.round(t * RATE), len = Math.round(dur * RATE);
  const from = slideFrom ?? midi;
  let ph = 0;
  let lp1 = 0, lp2 = 0;
  for (let i = 0; i < len; i++) {
    const tt = i / RATE;
    const slide = Math.min(1, tt / 0.07);
    const vibAmt = Math.min(1, Math.max(0, (tt - 0.18) / 0.3)) * 0.35;
    const m = from + (midi - from) * slide + Math.sin(2 * Math.PI * 5.6 * tt) * vibAmt;
    ph += mtof(m) / RATE;
    const saw = 2 * (ph - Math.floor(ph)) - 1;
    const bow = noise() * 0.08;
    // Two one-pole lowpasses: a bright attack mellowing out.
    const cut = 0.25 + 0.15 * Math.exp(-tt * 6);
    lp1 += cut * (saw + bow - lp1);
    lp2 += cut * (lp1 - lp2);
    const env = Math.min(1, tt / 0.06) * Math.min(1, (dur - tt) / 0.08);
    mix.add(s0 + i, lp2 * amp * env, pan, send);
  }
}

// Dizi: sine with a little second and third harmonic, breath and vibrato.
function dizi(mix, t, midi, beats, spb, amp, { pan = -0.15, send = 0.45 } = {}) {
  const dur = beats * spb;
  const s0 = Math.round(t * RATE), len = Math.round(dur * RATE);
  let ph = 0, br = 0;
  for (let i = 0; i < len; i++) {
    const tt = i / RATE;
    const vib = Math.min(1, Math.max(0, (tt - 0.15) / 0.25)) * 0.18;
    ph += mtof(midi + Math.sin(2 * Math.PI * 5.2 * tt) * vib) / RATE;
    const p = 2 * Math.PI * ph;
    br += 0.3 * (noise() - br);
    const v = Math.sin(p) + 0.25 * Math.sin(2 * p) + 0.08 * Math.sin(3 * p) + br * 0.12;
    const env = Math.min(1, tt / 0.05) * Math.min(1, (dur - tt) / 0.06) * (1 - 0.15 * Math.min(1, tt / dur));
    mix.add(s0 + i, v * amp * env, pan, send);
  }
}

// Soft pad / drone of detuned sines.
function pad(mix, t, midis, dur, amp, { pan = 0, send = 0.5 } = {}) {
  const s0 = Math.round(t * RATE), len = Math.round(dur * RATE);
  for (const m of midis) {
    for (const det of [-0.06, 0.06]) {
      const f = mtof(m + det);
      for (let i = 0; i < len; i++) {
        const tt = i / RATE;
        const env = Math.min(1, tt / 0.8) * Math.min(1, (dur - tt) / 0.8);
        mix.add(s0 + i, Math.sin(2 * Math.PI * f * tt) * amp * env / midis.length, pan + det * 4, send);
      }
    }
  }
}

function drum(mix, t, amp, { f0 = 140, f1 = 48, dec = 7, len = 0.5, pan = 0, send = 0.25, click = 0.5 } = {}) {
  const s0 = Math.round(t * RATE), n = Math.round(len * RATE);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const k = i / n, tt = i / RATE;
    ph += (f0 * Math.pow(f1 / f0, k)) / RATE;
    const v = Math.sin(2 * Math.PI * ph) * Math.exp(-dec * k) + (tt < 0.012 ? noise() * click * (1 - tt / 0.012) : 0);
    mix.add(s0 + i, v * amp, pan, send);
  }
}

function block(mix, t, amp, { f = 900, pan = 0.4 } = {}) {
  const s0 = Math.round(t * RATE), n = Math.round(0.07 * RATE);
  for (let i = 0; i < n; i++) {
    const k = i / n;
    mix.add(s0 + i, Math.sin(2 * Math.PI * f * (1 - 0.2 * k) * i / RATE) * Math.exp(-9 * k) * amp, pan, 0.2);
  }
}

function cymbal(mix, t, amp, { len = 1.4, pan = 0.3 } = {}) {
  const s0 = Math.round(t * RATE), n = Math.round(len * RATE);
  let a = 0, b = 0;
  for (let i = 0; i < n; i++) {
    const k = i / n;
    const x = noise();
    a += 0.6 * (x - a);
    b = x - a; // crude highpass
    mix.add(s0 + i, b * Math.exp(-4 * k) * amp, pan, 0.35);
  }
}

function gong(mix, t, base, amp, { len = 3, pan = 0 } = {}) {
  const parts = [1, 1.48, 1.92, 2.56, 3.2, 4.1, 5.3];
  const s0 = Math.round(t * RATE), n = Math.round(len * RATE);
  for (let p = 0; p < parts.length; p++) {
    const f = base * parts[p], a = amp / (p + 1.3), dec = 1.2 + p * 0.9;
    for (let i = 0; i < n; i++) {
      const tt = i / RATE;
      // A slight upward bloom, the gong's signature.
      const ff = f * (1 + 0.004 * (1 - Math.exp(-tt * 3)));
      mix.add(s0 + i, Math.sin(2 * Math.PI * ff * tt) * a * Math.exp(-dec * tt) * Math.min(1, tt / 0.01), pan, 0.5);
    }
  }
}

function windNoise(mix, t, dur, amp) {
  const s0 = Math.round(t * RATE), n = Math.round(dur * RATE);
  let lp = 0;
  for (let i = 0; i < n; i++) {
    const tt = i / RATE;
    const sw = 0.5 + 0.5 * Math.sin(2 * Math.PI * tt / 6.3) * Math.sin(2 * Math.PI * tt / 2.7);
    lp += (0.02 + 0.04 * sw) * (noise() - lp);
    mix.add(s0 + i, lp * amp * sw * Math.min(1, tt / 2, (dur - tt) / 2), Math.sin(tt * 0.3) * 0.6, 0.2);
  }
}

// ---------------------------------------------------------------- reverb

function reverb(mix, wet = 0.28, size = 1) {
  const combsL = [1116, 1188, 1277, 1356].map((d) => Math.round(d * size * RATE / 44100));
  const combsR = combsL.map((d) => d + 23);
  const aps = [556, 441].map((d) => Math.round(d * RATE / 44100));
  function chan(delays) {
    const out = new Float64Array(mix.n);
    for (const d of delays) {
      const buf = new Float64Array(d);
      let idx = 0, filt = 0;
      for (let i = 0; i < mix.n; i++) {
        const y = buf[idx];
        filt = y * 0.8 + filt * 0.2;
        buf[idx] = mix.S[i] + filt * 0.82;
        idx = (idx + 1) % d;
        out[i] += y / delays.length;
      }
    }
    for (const d of aps) {
      const buf = new Float64Array(d);
      let idx = 0;
      for (let i = 0; i < mix.n; i++) {
        const b = buf[idx];
        const y = -out[i] + b;
        buf[idx] = out[i] + b * 0.5;
        idx = (idx + 1) % d;
        out[i] = y;
      }
    }
    return out;
  }
  const l = chan(combsL), r = chan(combsR);
  for (let i = 0; i < mix.n; i++) {
    mix.L[i] += l[i] * wet;
    mix.R[i] += r[i] * wet;
  }
}

// ---------------------------------------------------------------- output

function writeWav(name, mix, loopSamples) {
  // Fold everything after the loop point back onto the start.
  const L = mix.L.slice(0, loopSamples), R = mix.R.slice(0, loopSamples);
  for (let i = loopSamples; i < mix.n; i++) {
    L[i - loopSamples] += mix.L[i];
    R[i - loopSamples] += mix.R[i];
  }
  // Level every track to the same loudness (RMS), then a soft limiter so
  // gong hits and drum peaks round off instead of clipping.
  let sq = 0;
  for (let i = 0; i < loopSamples; i++) sq += L[i] * L[i] + R[i] * R[i];
  const rms = Math.sqrt(sq / (2 * loopSamples));
  const target = Math.pow(10, -17 / 20);
  const pre = target / rms;
  const soft = (x) => Math.tanh(x * pre * 1.1) / 1.1;
  let peak = 0;
  for (let i = 0; i < loopSamples; i++) {
    L[i] = soft(L[i]);
    R[i] = soft(R[i]);
    peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
  }
  const gain = peak > 0.89 ? 0.89 / peak : 1;
  const data = Buffer.alloc(loopSamples * 4);
  for (let i = 0; i < loopSamples; i++) {
    data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i] * gain)) * 32767), i * 4);
    data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i] * gain)) * 32767), i * 4 + 2);
  }
  const head = Buffer.alloc(44);
  head.write('RIFF', 0);
  head.writeUInt32LE(36 + data.length, 4);
  head.write('WAVEfmt ', 8);
  head.writeUInt32LE(16, 16);
  head.writeUInt16LE(1, 20);
  head.writeUInt16LE(2, 22);
  head.writeUInt32LE(RATE, 24);
  head.writeUInt32LE(RATE * 4, 28);
  head.writeUInt16LE(4, 32);
  head.writeUInt16LE(16, 34);
  head.write('data', 36);
  head.writeUInt32LE(data.length, 40);
  fs.writeFileSync(path.join(OUT, name + '.wav'), Buffer.concat([head, data]));
  console.log(name, (loopSamples / RATE).toFixed(1) + 's');
}

// ---------------------------------------------------------------- arranging

/// Plays a melody line on an instrument, starting at [t0].
function melody(mix, line, { t0 = 0, spb, root, mode, inst, amp, oct = 0, pan, send, grace = false }) {
  let t = t0;
  let prev = null;
  for (const n of parse(line)) {
    if (n.d !== null) {
      const midi = degreeToMidi(root, mode, n.d) + 12 * oct;
      if (inst === 'erhu') {
        erhu(mix, t, midi, n.beats * 0.97, spb, amp, { pan, send, slideFrom: prev !== null && Math.abs(prev - midi) <= 5 && rnd() < 0.5 ? prev : null });
      } else if (inst === 'dizi') {
        dizi(mix, t, midi, n.beats * 0.95, spb, amp, { pan, send });
      } else if (inst === 'zheng') {
        if (grace && n.beats >= 1 && rnd() < 0.4) pluck(mix, t - 0.07, midi + 2, amp * 0.5, { pan, send });
        pluck(mix, t, midi, amp, { pan, send, dur: Math.max(1.2, n.beats * spb + 0.8) });
      } else if (inst === 'pipa') {
        // Tremolo: rapid repeated plucks across the note.
        const step = 0.065;
        for (let k = 0; k * step < n.beats * spb * 0.95; k++) {
          pluck(mix, t + k * step, midi, amp * (0.75 + 0.25 * rnd()), { pan, send, dur: 0.35, bright: 0.8 });
        }
      }
      prev = midi;
    }
    t += n.beats * spb;
  }
  return t;
}

/// Guzheng arpeggio under a chord per bar (degree of the chord root).
function arpeggio(mix, chords, { t0 = 0, spb, root, mode, amp, pattern = [0, 2, 4, 5], per = 0.5, oct = -1, pan = 0.35 }) {
  let t = t0;
  for (const c of chords) {
    const beats = 4;
    for (let k = 0; k * per < beats; k++) {
      const d = c + pattern[k % pattern.length];
      pluck(mix, t + k * per * spb, degreeToMidi(root, mode, d) + 12 * oct, amp * (k % pattern.length === 0 ? 1 : 0.7), { pan, send: 0.3, dur: 1.4, bright: 0.45 });
    }
    t += beats * spb;
  }
}

function drone(mix, chords, { t0 = 0, spb, root, mode, amp, oct = -2 }) {
  let t = t0;
  for (const c of chords) {
    const a = degreeToMidi(root, mode, c) + 12 * oct;
    pad(mix, t, [a, a + 7], 4 * spb + 0.5, amp);
    t += 4 * spb;
  }
}

function track(name, bars, bpm, build, { tail = 3, wet = 0.28, size = 1 } = {}) {
  if (process.argv[2] && process.argv[2] !== name) return;
  seed = name.split('').reduce((a, c) => a * 31 + c.charCodeAt(0), 7) & 0x7fffff;
  const spb = 60 / bpm;
  const loop = bars * 4 * spb;
  const mix = new Mix(loop + tail);
  build(mix, spb, loop);
  reverb(mix, wet, size);
  writeWav(name, mix, Math.round(loop * RATE));
}

// ---------------------------------------------------------------- VN extras

// Đàn bầu: a single string played as a harmonic — nearly pure tone, a soft
// attack, long ring — with the rod bending into each note (luyến) and a
// wide, slow vibrato (rung) on held notes.
function danbau(mix, t, midi, beats, spb, amp, { pan = 0.1, send = 0.45, from = null } = {}) {
  const dur = beats * spb;
  const ring = dur + 0.5;
  const s0 = Math.round(t * RATE), len = Math.round(ring * RATE);
  const start = from ?? midi - 1;
  const bend = Math.abs(start - midi) > 0 ? 0.12 + 0.03 * Math.abs(start - midi) : 0;
  let ph = 0;
  for (let i = 0; i < len; i++) {
    const tt = i / RATE;
    const sl = bend > 0 ? Math.min(1, tt / bend) : 1;
    const ease = sl * sl * (3 - 2 * sl);
    const vib = Math.min(1, Math.max(0, (tt - 0.35) / 0.4)) * 0.45 * (dur > 0.6 ? 1 : 0.3);
    const m = start + (midi - start) * ease + Math.sin(2 * Math.PI * 4.6 * tt) * vib;
    ph += mtof(m) / RATE;
    const p = 2 * Math.PI * ph;
    const v = Math.sin(p) + 0.12 * Math.sin(2 * p) * Math.exp(-tt * 3) + 0.05 * Math.sin(3 * p) * Math.exp(-tt * 5);
    const click = tt < 0.008 ? noise() * 0.25 * (1 - tt / 0.008) : 0;
    const env = Math.min(1, tt / 0.012) * Math.exp(-tt * 0.9) * (tt > dur ? Math.max(0, 1 - (tt - dur) / 0.5) : 1);
    mix.add(s0 + i, (v * env + click) * amp, pan, send);
  }
}

function lineVN(mix, line, { t0 = 0, spb, root, mode, inst, amp, oct = 0, pan, send, grace = false }) {
  if (inst !== 'danbau') return melody(mix, line, { t0, spb, root, mode, inst, amp, oct, pan, send, grace });
  let t = t0, prev = null;
  for (const n of parse(line)) {
    if (n.d !== null) {
      const midi = degreeToMidi(root, mode, n.d) + 12 * oct;
      // Mostly slide in from the previous note when it is close, otherwise
      // scoop up from a semitone under.
      const from = prev !== null && Math.abs(prev - midi) <= 5 && rnd() < 0.6 ? prev : (rnd() < 0.5 ? midi - 1 : midi);
      danbau(mix, t, midi, n.beats, spb, amp, { pan, send, from });
      prev = midi;
    }
    t += n.beats * spb;
  }
  return t;
}

// Song lang: the small wooden clapper of cải lương, a dry high click.
function songLang(mix, t, amp, pan = -0.3) {
  const s0 = Math.round(t * RATE), n = Math.round(0.04 * RATE);
  for (let i = 0; i < n; i++) {
    const k = i / n;
    mix.add(s0 + i, (Math.sin(2 * Math.PI * 2100 * i / RATE) * 0.6 + noise() * 0.4) * Math.exp(-14 * k) * amp, pan, 0.15);
  }
}

function bird(mix, t, amp) {
  const pan = rnd() * 1.6 - 0.8;
  const notes = 2 + Math.floor(rnd() * 4);
  const base = 2800 + rnd() * 1800;
  for (let j = 0; j < notes; j++) {
    const s0 = Math.round((t + j * 0.09) * RATE), n = Math.round(0.065 * RATE);
    const f0 = base * (1 + 0.15 * rnd()), up = rnd() < 0.5;
    let ph = 0;
    for (let i = 0; i < n; i++) {
      const k = i / n;
      ph += (f0 * (up ? 0.8 + 0.4 * k : 1.2 - 0.4 * k) * (1 + 0.04 * Math.sin(k * 60))) / RATE;
      mix.add(s0 + i, Math.sin(2 * Math.PI * ph) * Math.sin(Math.PI * k) * amp, pan, 0.35);
    }
  }
}

function crickets(mix, dur, amp) {
  for (let c = 0; c < 2; c++) {
    const f = c ? 4700 : 4100, pan = c ? 0.6 : -0.6, rate = c ? 3.1 : 2.4;
    const n = Math.min(mix.n, Math.round(dur * RATE));
    for (let i = 0; i < n; i++) {
      const tt = i / RATE;
      // Trills of fast pulses, a few per second.
      if ((tt * rate) % 1 >= 0.28) continue;
      const pulse = Math.max(0, Math.sin(2 * Math.PI * 32 * tt));
      mix.add(i, Math.sin(2 * Math.PI * f * tt) * pulse * amp, pan, 0.25);
    }
  }
}

// ---------------------------------------------------------------- the music

// Đồng quê (day): sáo trúc sings over đàn tranh, đàn bầu takes the middle
// verse; birds and a light mõ / song lang pulse. G in the Bắc pentatonic.
track('dong_que', 24, 92, (mix, spb) => {
  const key = { root: 67, mode: 'zhi', spb };
  const A = '2:1 3:1 4:1.5 3:.5 | 4:1 5:1 4:2 | 3:1 2:1 1:1 2:1 | 0:3 r:1 | 1:1 2:1 4:1 5:1 | 6:1.5 5:.5 4:2 | 3:1 4:1 2:1 1:1 | 2:4';
  const B = '5:2 4:1 3:1 | 4:3 r:1 | 2:1.5 3:.5 4:1 2:1 | 1:4 | 2:2 4:1 5:1 | 4:1.5 3:.5 2:2 | 1:1 2:1 0:1 -1:1 | 0:4';
  const A2 = '2:1 3:1 4:1.5 3:.5 | 4:1 5:1 4:2 | 3:1 2:1 1:1 2:1 | 0:3 r:1 | 1:1 2:1 4:1 5:1 | 6:1.5 5:.5 4:1 3:1 | 2:1 1:1 -1:1 1:1 | 0:4';
  const chords = [0, 3, 1, 0, 1, 3, 1, 0, 3, 3, 1, 1, 0, 3, 1, 0, 0, 3, 1, 0, 1, 3, 1, 0];
  const bar = 4 * spb;
  lineVN(mix, A, { ...key, inst: 'dizi', amp: 0.32, pan: -0.15 });
  lineVN(mix, B, { ...key, t0: 8 * bar, inst: 'danbau', amp: 0.42, oct: -1, pan: 0.1 });
  // The flute answers the đàn bầu softly in its rests.
  lineVN(mix, 'r:12 6:1 5:1 4:2 | r:12 2:1 4:1 5:2', { ...key, t0: 8 * bar, inst: 'dizi', amp: 0.14, pan: -0.45 });
  lineVN(mix, A2, { ...key, t0: 16 * bar, inst: 'dizi', amp: 0.3, pan: -0.15 });
  lineVN(mix, 'r:4 0:4 | r:4 2:4 | r:4 1:4 | r:4 0:4', { ...key, t0: 16 * bar, inst: 'danbau', amp: 0.22, oct: -1, pan: 0.35 });
  arpeggio(mix, chords, { ...key, amp: 0.24, pattern: [0, 2, 4, 2], per: 0.5, oct: -1 });
  drone(mix, chords, { ...key, amp: 0.06 });
  for (let b = 0; b < 24; b++) {
    const t = b * bar;
    block(mix, t, 0.12, { f: 760, pan: 0.3 });
    block(mix, t + 2 * spb, 0.08, { f: 760, pan: 0.3 });
    songLang(mix, t + 1.5 * spb, 0.07);
    if (b % 2 === 1) songLang(mix, t + 3.5 * spb, 0.06);
  }
  for (let k = 0; k < 14; k++) bird(mix, rnd() * 24 * bar, 0.035);
}, { wet: 0.3, size: 1.1 });

// Chiều quê (evening): slower, đàn bầu leads in the Nam (oán) colour over
// sparse đàn tranh, sáo joins late; crickets underneath. D yu pentatonic.
track('chieu_que', 16, 70, (mix, spb) => {
  const key = { root: 62, mode: 'yu', spb };
  const A = '2:2 3:1 2:1 | 0:3 r:1 | 1:1.5 2:.5 3:1 4:1 | 3:4 | 4:2 3:1 2:1 | 1:1.5 0:.5 -1:2 | 0:1 1:1 2:1 1:1 | 0:4';
  const B = '5:2 4:1 3:1 | 4:3 r:1 | 3:1.5 2:.5 1:1 2:1 | 3:4 | 2:2 1:1 0:1 | -1:1.5 0:.5 1:2 | 2:1 1:1 -1:1 -2:1 | 0:4';
  const chords = [0, 0, 3, 2, 3, 4, 3, 0, 3, 3, 2, 2, 1, 4, 3, 0];
  const bar = 4 * spb;
  lineVN(mix, A + ' ' + B, { ...key, inst: 'danbau', amp: 0.42, pan: 0.05, send: 0.5 });
  lineVN(mix, 'r:32 r:2 7:2 | 6:4 | r:2 5:2 | 6:4 | r:2 4:2 | 3:4', { ...key, inst: 'dizi', amp: 0.13, pan: -0.45, send: 0.6 });
  lineVN(mix, 'r:1 0:3 | r:1 2:3 | r:1 3:3 | r:1 2:3 | r:1 3:3 | r:1 4:3 | r:1 3:3 | r:1 0:3 | r:1 3:3 | r:1 3:3 | r:1 2:3 | r:1 2:3 | r:1 1:3 | r:1 4:3 | r:1 3:3 | r:1 0:3',
    { ...key, inst: 'zheng', amp: 0.26, oct: -1, grace: true, pan: 0.4 });
  drone(mix, chords, { ...key, amp: 0.08 });
  for (let b = 0; b < 16; b++) {
    block(mix, b * bar, 0.08, { f: 640, pan: 0.25 });
    if (b % 2 === 1) songLang(mix, b * bar + 3 * spb, 0.05);
  }
  crickets(mix, 16 * bar + 3, 0.012);
}, { wet: 0.36, size: 1.25 });
