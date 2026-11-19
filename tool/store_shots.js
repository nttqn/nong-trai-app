// Store screenshots (portrait) for Google Play from the web demo build.
// NODE_PATH must point at a Playwright install; build/web served on :8790.
//   node tool/store_shots.js [device] [shotPrefix]
const fs = require('fs');
const { chromium } = require('playwright');

// logical viewport x device scale = the pixel size the store asks for
const devices = [
  ['phone', 360, 720, 3], // Play phone 1080x2160
  ['tablet-7in', 600, 960, 2], // Play 7" tablet 1200x1920
  ['tablet-10in', 800, 1280, 2], // Play 10" tablet 1600x2560
];

const base = 'shot=1&weather=sunny';
const shots = [
  ['01-lang-que', `demo=3&${base}&day=2026-11-06`, 8000],
  ['02-tet', `demo=3&${base}&day=2027-02-06&fest=1&fx=4&fy=13&zoom=1.7`, 9000],
  ['03-phoi-thoc', `demo=3&${base}&day=2026-11-06&fx=16&fy=8&zoom=1.8`, 8000],
  ['04-lang-nhon-nhip', `demo=3&${base}&day=2026-11-06&fx=11&fy=6&zoomw=1.4`, 8000],
  ['05-lich-le-hoi', `demo=3&${base}&day=2026-09-25&sheet=calendar`, 9000],
  ['06-ky-uc', `demo=3&${base}&day=2026-11-06&memcard=tet_sum_vay`, 10000],
  ['07-dem-trang', `demo=3&shot=1&weather=sunny&day=2026-11-23&hour=21.2&fx=12&fy=9&zoomw=1.15`, 10000],
  ['08-cua-hang', `demo=3&${base}&day=2026-11-06&sheet=paid`, 9000],
];

(async () => {
  const onlyDevice = process.argv[2];
  const onlyShot = process.argv[3];
  const browser = await chromium.launch();
  for (const [dev, w, h, dpr] of devices) {
    if (onlyDevice && dev !== onlyDevice) continue;
    fs.mkdirSync(`store/${dev}`, { recursive: true });
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: dpr });
    // one at a time: in parallel the emoji font and pictures load too late
    for (const [name, q, wait] of shots.filter(([n]) => !onlyShot || n.startsWith(onlyShot))) {
      const page = await ctx.newPage();
      // zoomw=: a zoom for the phone width, scaled up on wider screens so
      // tablets frame the same part of the farm
      const qq = q.replace(/zoomw=([\d.]+)/, (_, z) => `zoom=${(z * Math.max(1, w / 360 * .7)).toFixed(2)}`);
      await page.goto(`http://localhost:8790/?${qq}&nocache=${Date.now()}`);
      await page.waitForTimeout(wait + 4000);
      await page.screenshot({ path: `store/${dev}/${name}.png` });
      await page.close();
    }
    await ctx.close();
    console.log(dev, `${w * dpr}x${h * dpr}`);
  }
  await browser.close();
})();
