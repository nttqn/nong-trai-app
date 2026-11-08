// Assembles the narrated promo: portrait scenes timed to the voice lines,
// a few game sound effects, the "Đồng quê" theme ducked under the voice,
// Vietnamese subtitles, an end card. Writes out/mua-lua-chin-promo-9x16.mp4
// (Shorts/TikTok/Reels) and -16x9.mp4 (YouTube: the portrait game in the
// middle, title and subtitles beside it). node build.js
const fs = require('fs');
const { execFileSync } = require('child_process');

const FFDIR = 'C:/Users/Hi/AppData/Local/Temp/claude/c--Users-Hi--gemini-antigravity-scratch-finance-app/569b67c7-8a47-45d9-82e4-06715cbf6635/scratchpad/ffmpeg/ffmpeg-n8.1-latest-win64-gpl-8.1/bin';
const FF = `${FFDIR}/ffmpeg.exe`, FP = `${FFDIR}/ffprobe.exe`;
const P = 'C:/Users/Hi/.gemini/antigravity/scratch/nong-trai-app';
const MUSIC = `${P}/assets/audio/music/dong_que.ogg`;
const ICON = `${P}/store/icon-512.png`;
const SFX = `${P}/assets/audio`;
const FONT = 'fonts/BeVietnamPro-ExtraBold.ttf';
const FONT_R = 'fonts/BeVietnamPro-Bold.ttf';

const ff = (args) => execFileSync(FF, ['-hide_banner', '-loglevel', 'error', '-y', ...args], { stdio: 'inherit' });
const dur = (f) => parseFloat(execFileSync(FP, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f]).toString());
const ENC = ['-r', '30', '-c:v', 'libx264', '-crf', '17', '-preset', 'medium', '-pix_fmt', 'yuv420p', '-an'];

for (const d of ['clips', 'seg', 'out', 'txt']) fs.mkdirSync(d, { recursive: true });
fs.writeFileSync('txt/title.txt', 'MÙA LÚA CHÍN');
fs.writeFileSync('txt/tagline.txt', 'Nông trại làng quê Việt');
fs.writeFileSync('txt/cta.txt', 'TẢI MIỄN PHÍ TRÊN GOOGLE PLAY');

// frames → clips (1080x1920, 30 fps)
const clip = (name) => {
  const out = `clips/${name}.mp4`;
  if (!fs.existsSync(out)) ff(['-f', 'concat', '-safe', '0', '-i', `frames/${name}/list.txt`, '-vf', 'fps=30,scale=1080:1920', ...ENC, out]);
  return out;
};

// sound effects per scene: [file, seconds into the scene, volume]
const EFFECTS = {
  s2: [['harvest', 0.25, 0.7], ['harvest', 0.75, 0.6], ['harvest', 1.25, 0.7], ['harvest', 1.75, 0.6], ['harvest', 2.25, 0.7], ['coin', 2.7, 0.4]],
  s3: [['ga', 0.4, 0.5], ['vit', 1.6, 0.5], ['trau', 2.8, 0.45]],
  s4: [['place', 2.6, 0.6]],
  s5: [['sparkle', 0.3, 0.6]],
  s7: [['quest', 0.2, 0.6]],
  s8: [['tap', 0.3, 0.6]],
  s9: [['levelup', 0.1, 0.7]],
};

const script = JSON.parse(fs.readFileSync('script.json', 'utf8'));
const GAP = 0.8;
let t = 0;
const segs = [], sfx = [], subs = [], voices = [];
for (const [n, line] of script.entries()) {
  const vfile = `voice/${line.id}.wav`;
  const lead = n === 0 ? 0.4 : 0;
  const len = dur(vfile) + GAP + lead;
  voices.push({ at: t + lead, file: vfile });
  fs.writeFileSync(`txt/${line.id}.txt`, line.sub);
  subs.push({ from: t + lead, to: t + len - 0.1, file: `txt/${line.id}.txt`, id: line.id });
  for (const [f, at, vol] of EFFECTS[line.id] ?? []) sfx.push({ at: t + at, file: `${SFX}/${f}.wav`, vol });
  const out = `seg/${line.id}.mp4`;
  const [kind, arg] = line.scene.split(':');
  if (kind === 'clip' || kind === 'clips') {
    const names = arg.split(',');
    const each = len / names.length;
    const parts = names.map((name, i) => {
      const p = `seg/${line.id}_${i}.mp4`;
      const start = i === 0 ? line.at ?? 0 : 0;
      // hold the last frame if the line runs longer than the recording
      ff(['-ss', start.toFixed(3), '-i', clip(name), '-vf', 'tpad=stop_mode=clone:stop_duration=6', '-t', each.toFixed(3), ...ENC, p]);
      return p;
    });
    ff([...parts.flatMap((p) => ['-i', p]), '-filter_complex', `${parts.map((_, i) => `[${i}]`).join('')}concat=n=${parts.length}:v=1:a=0`, ...ENC, out]);
  } else if (kind === 'end') {
    const hold = len + 1.2;
    ff(['-ss', '3', '-i', clip('a_village'), '-frames:v', '1', 'seg/bg.png']);
    ff(['-loop', '1', '-framerate', '30', '-t', hold.toFixed(3), '-i', 'seg/bg.png', '-i', ICON, '-filter_complex',
      '[0]scale=1080:1920,boxblur=20:3,eq=brightness=-0.22[b];[1]scale=300:300[i];[b][i]overlay=(W-w)/2:470[bi];' +
      `[bi]drawtext=fontfile=${FONT}:textfile=txt/title.txt:fontsize=118:fontcolor=0xFFE082:borderw=6:bordercolor=0x3B2A14:x=(w-text_w)/2:y=830,` +
      `drawtext=fontfile=${FONT_R}:textfile=txt/tagline.txt:fontsize=58:fontcolor=white:borderw=4:bordercolor=0x3B2A14:x=(w-text_w)/2:y=990,` +
      `drawtext=fontfile=${FONT}:textfile=txt/cta.txt:fontsize=50:fontcolor=white:box=1:boxcolor=0x3F7A1C:boxborderw=30:x=(w-text_w)/2:y=1180,` +
      'fade=t=in:st=0:d=0.4', ...ENC, out]);
    segs.push(out);
    t += hold;
    continue;
  }
  segs.push(out);
  t += len;
}
const TOTAL = t;
console.log('total', TOTAL.toFixed(2), 's');

ff([...segs.flatMap((s) => ['-i', s]), '-filter_complex', `${segs.map((_, i) => `[${i}]`).join('')}concat=n=${segs.length}:v=1:a=0`, ...ENC, 'seg/master.mp4']);

// audio: music ducked under the voice, plus the effects
const mix = (items, outFile) => {
  const chains = items.map((s, i) => `[${i}]aresample=44100,aformat=channel_layouts=stereo,volume=${s.vol ?? 1},adelay=${Math.round(s.at * 1000)}|${Math.round(s.at * 1000)}[a${i}]`);
  ff([...items.flatMap((s) => ['-i', s.file]), '-filter_complex',
    `${chains.join(';')};${items.map((_, i) => `[a${i}]`).join('')}amix=inputs=${items.length}:normalize=0:duration=longest,apad=whole_dur=${TOTAL.toFixed(3)}[o]`,
    '-map', '[o]', '-t', TOTAL.toFixed(3), '-c:a', 'pcm_s16le', outFile]);
};
mix(sfx, 'seg/sfx.wav');
mix(voices, 'seg/voice.wav');
ff(['-stream_loop', '-1', '-i', MUSIC, '-i', 'seg/voice.wav', '-i', 'seg/sfx.wav', '-filter_complex',
  `[0]atrim=0:${TOTAL.toFixed(3)},aresample=44100,aformat=channel_layouts=stereo,volume=0.6,afade=t=in:d=0.5,afade=t=out:st=${(TOTAL - 2.5).toFixed(2)}:d=2.5[m];` +
  '[1]asplit=2[v][vk];[m][vk]sidechaincompress=threshold=0.03:ratio=6:attack=30:release=400[md];' +
  '[2]volume=0.9[fx];[md][v][fx]amix=inputs=3:normalize=0,alimiter=limit=0.95[o]',
  '-map', '[o]', '-t', TOTAL.toFixed(3), '-c:a', 'pcm_s16le', 'seg/mix.wav']);

// subtitles: two lines, fade in; none on the end card
const subFilter = (size, y, xExpr = '(w-text_w)/2') => subs.filter((s) => s.id !== 's9').map((s) =>
  `drawtext=fontfile=${FONT}:textfile=${s.file}:fontsize=${size}:fontcolor=white:line_spacing=14:text_align=center:` +
  `borderw=4:bordercolor=0x2B1D0E:box=1:boxcolor=0x2B1D0E@0.62:boxborderw=26:x=${xExpr}:y=${y}:` +
  `enable='between(t,${s.from.toFixed(2)},${s.to.toFixed(2)})':alpha='if(lt(t-${s.from.toFixed(2)},0.25),(t-${s.from.toFixed(2)})/0.25,1)'`).join(',');
const endAt = (TOTAL - (dur('voice/s9.wav') + GAP + 1.2)).toFixed(2);

// 9:16: the game full screen, subtitles in the lower middle of the map
ff(['-i', 'seg/master.mp4', '-i', 'seg/mix.wav', '-filter_complex', `[0]${subFilter(66, 1420)}[v]`,
  '-map', '[v]', '-map', '1:a', '-r', '30', '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', '-pix_fmt', 'yuv420p',
  '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', 'out/mua-lua-chin-promo-9x16.mp4']);

// 16:9: blurred fill, the portrait game in the middle, icon and title on
// the left, subtitles on the right; the end card fills the frame
ff(['-i', 'seg/master.mp4', '-i', 'seg/mix.wav', '-i', ICON, '-filter_complex',
  '[0]split[x][y];[x]scale=1920:-2,crop=1920:1080,boxblur=28:4,eq=brightness=-0.18[bg];[y]scale=-2:1080[fg];' +
  '[2]scale=200:200[ic];[bg][fg]overlay=(W-w)/2:0[b1];' +
  `[b1][ic]overlay=(656-200)/2:300:enable='lt(t,${endAt})',` +
  `drawtext=fontfile=${FONT}:textfile=txt/title.txt:fontsize=72:fontcolor=0xFFE082:borderw=5:bordercolor=0x3B2A14:x=(656-text_w)/2:y=540:enable='lt(t,${endAt})',` +
  `drawtext=fontfile=${FONT_R}:textfile=txt/tagline.txt:fontsize=36:fontcolor=white:borderw=3:bordercolor=0x3B2A14:x=(656-text_w)/2:y=640:enable='lt(t,${endAt})',` +
  `${subFilter(54, 470, '1264+(656-text_w)/2')}[v]`,
  '-map', '[v]', '-map', '1:a', '-r', '30', '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', '-pix_fmt', 'yuv420p',
  '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', 'out/mua-lua-chin-promo-16x9.mp4']);
console.log('done');
