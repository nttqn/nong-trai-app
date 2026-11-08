// Records promo scenes from the web demo build (served on :8790) through
// Chrome's screencast, portrait 1080x1920. The game runs SLOW times slower
// (?slow= in lib/main.dart) so every frame is caught; frame times are
// divided back. node capture.js <outDir> <scene|all>
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const W = 540, H = 960; // CSS px; frames are 2x
const SLOW = 5;
const base = 'shot=1&weather=sunny';
// screen point of tile (x, y) when the camera centres (fx, fy) at zoom z
const tile = (x, y, fx, fy, z) => [W / 2 + z * 32 * ((x - y) - (fx - fy)), H / 2 + z * 16 * ((x + y) - (fx + fy))];
const wait = (p, ms) => p.waitForTimeout(ms * SLOW); // in game time

async function swipe(page, pts, ms) {
  await page.mouse.move(...pts[0]);
  await page.mouse.down();
  const steps = 12;
  for (let i = 1; i < pts.length; i++) {
    const [ax, ay] = pts[i - 1], [bx, by] = pts[i];
    for (let k = 1; k <= steps; k++) {
      await page.mouse.move(ax + (bx - ax) * k / steps, ay + (by - ay) * k / steps);
      await wait(page, ms / steps / (pts.length - 1));
    }
  }
  await page.mouse.up();
}

const scenes = {
  // slow pan over the whole village
  a_village: { q: `demo=3&${base}&day=2026-11-06&fx=9&fy=9&zoom=1.15`, secs: 7, act: async (p) => {
    await wait(p, 300);
    await swipe(p, [[400, 520], [170, 460]], 6200);
  } },
  // swipe across two rows of ripe rice
  b_harvest: { q: `demo=3&${base}&day=2026-11-06&ripe=1&fx=14.5&fy=9.5&zoom=2.6`, secs: 6, act: async (p) => {
    const z = 2.6, f = [14.5, 9.5];
    await wait(p, 900);
    await swipe(p, [tile(13.5, 9.5, ...f, z), tile(16.5, 9.5, ...f, z), tile(16.5, 10.5, ...f, z), tile(13.5, 10.5, ...f, z)], 2400);
  } },
  c_pens: { q: `demo=3&${base}&day=2026-11-06&fx=8&fy=14.5&zoom=2.1`, secs: 6 },
  d_yard: { q: `demo=3&${base}&day=2026-11-06&fx=17&fy=9.5&zoom=2.3`, secs: 4.5 },
  e_rain: { q: `demo=3&shot=1&weather=rain&yard=cover&day=2026-11-06&fx=17&fy=9.5&zoom=2.3`, secs: 4.5 },
  f_tet: { q: `demo=3&${base}&day=2027-02-06&fest=1&fx=4&fy=12.5&zoom=1.8`, secs: 7 },
  g_calendar: { q: `demo=3&${base}&day=2026-09-25&sheet=calendar`, secs: 5, act: async (p) => {
    await wait(p, 2200);
    await p.mouse.move(270, 700);
    for (let i = 0; i < 8; i++) { await p.mouse.wheel(0, 35); await wait(p, 80); }
  } },
  h_memory: { q: `demo=3&${base}&day=2026-11-06&memcard=tet_sum_vay`, secs: 5 },
  i_album: { q: `demo=3&${base}&day=2026-11-06&sheet=album`, secs: 5, act: async (p) => {
    await wait(p, 1500);
    await p.mouse.move(270, 650);
    for (let i = 0; i < 10; i++) { await p.mouse.wheel(0, 40); await wait(p, 90); }
  } },
  j_map: { q: `demo=3&${base}&day=2026-11-06&sheet=map&worldmap=demo`, secs: 5 },
};

(async () => {
  const [out, which] = process.argv.slice(2);
  const browser = await chromium.launch({ args: ['--force-device-scale-factor=2'] });
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
  for (const [name, s] of Object.entries(scenes)) {
    if (which !== 'all' && which !== name) continue;
    const dir = path.join(out, name);
    fs.rmSync(dir, { recursive: true, force: true });
    fs.mkdirSync(dir, { recursive: true });
    const page = await ctx.newPage();
    await page.goto(`http://localhost:8790/?${s.q}&slow=${SLOW}&nocache=${Date.now()}`);
    await page.waitForTimeout(12000); // load, sprites, emoji font, sheets open
    const cdp = await ctx.newCDPSession(page);
    await cdp.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 2, mobile: false });
    const frames = [];
    cdp.on('Page.screencastFrame', async (f) => {
      frames.push({ t: Date.now(), data: f.data });
      try { await cdp.send('Page.screencastFrameAck', { sessionId: f.sessionId }); } catch (_) {}
    });
    await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 92, maxWidth: W * 2, maxHeight: H * 2 });
    const t0 = Date.now();
    if (s.act) await s.act(page);
    await page.waitForTimeout(Math.max(0, s.secs * 1000 * SLOW - (Date.now() - t0)));
    await cdp.send('Page.stopScreencast');
    let list = 'ffconcat version 1.0\n';
    frames.forEach((f, i) => {
      const file = `f${String(i).padStart(5, '0')}.jpg`;
      fs.writeFileSync(path.join(dir, file), Buffer.from(f.data, 'base64'));
      const next = frames[i + 1];
      const d = next ? (next.t - f.t) / SLOW : 33;
      list += `file ${file}\nduration ${(d / 1000).toFixed(4)}\n`;
    });
    fs.writeFileSync(path.join(dir, 'list.txt'), list);
    const span = (frames[frames.length - 1].t - frames[0].t) / 1000 / SLOW;
    console.log(name, frames.length, 'frames over', span.toFixed(1), 's =', (frames.length / span).toFixed(1), 'fps');
    await page.close();
  }
  await browser.close();
})();
